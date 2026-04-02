//
//  BluetoothDeviceManager.swift
//  NotchX
//
//  Detects Bluetooth audio devices, reads battery levels, and publishes
//  state changes for display in the macOS notch.
//

import Combine
import CoreAudio
import CoreBluetooth
import Defaults
import IOBluetooth
import IOKit
import IOKit.ps
import Foundation
import SwiftUI

// MARK: - BluetoothDeviceManager

class BluetoothDeviceManager: NSObject, ObservableObject {

    static let shared = BluetoothDeviceManager()

    @Published var activeDevice: BluetoothAudioDevice? = nil

    private var audioListenerBlock: AudioObjectPropertyListenerBlock?
    private var centralManager: CBCentralManager?
    private var batteryPollingTimer: Timer?
    private var batteryRetryTask: Task<Void, Never>?
    private var previousActiveDeviceID: String? = nil
    private let coordinator = NotchXViewCoordinator.shared
    // BLE advertisement cache for AirPods case battery (Apple Continuity Protocol)
    private var bleCaseBattery: Int = -1
    private var bleLeftBattery: Int = -1
    private var bleRightBattery: Int = -1

    // IOBluetooth notification reference — retained to keep registration alive
    private var iOBluetoothConnectNotification: IOBluetoothUserNotification?

    private override init() {
        super.init()
        // Monitoring is started externally via startMonitoring() from AppDelegate
    }

    // MARK: - Public API

    func startMonitoring() {
        registerCoreAudioListener()

        if !isSandboxed {
            registerIOBluetoothNotifications()
        }

        refreshActiveAudioDevice()

        batteryPollingTimer = Timer.scheduledTimer(
            withTimeInterval: 30,
            repeats: true
        ) { [weak self] _ in
            self?.refreshBatteryFromIORegistry()
        }
    }

    func destroy() {
        removeCoreAudioListener()
        batteryPollingTimer?.invalidate()
        batteryPollingTimer = nil
        batteryRetryTask?.cancel()
        batteryRetryTask = nil
        iOBluetoothConnectNotification?.unregister()
        iOBluetoothConnectNotification = nil
        centralManager = nil
        DispatchQueue.main.async { [weak self] in
            self?.activeDevice = nil
        }
    }

    // MARK: - Computed Properties

    var isSandboxed: Bool {
        ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    // MARK: - CoreAudio Listener (Layer 1)

    private func registerCoreAudioListener() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let listenerBlock: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.refreshActiveAudioDevice()
        }
        audioListenerBlock = listenerBlock

        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.global(qos: .userInitiated),
            listenerBlock
        )
    }

    private func removeCoreAudioListener() {
        guard let block = audioListenerBlock else { return }
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.global(qos: .userInitiated),
            block
        )
        audioListenerBlock = nil
    }

    // MARK: - Refresh Active Audio Device

    private func refreshActiveAudioDevice() {
        var defaultDeviceID: AudioDeviceID = kAudioObjectUnknown
        var defaultDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultDeviceAddress,
            0,
            nil,
            &dataSize,
            &defaultDeviceID
        )

        guard status == noErr, defaultDeviceID != kAudioObjectUnknown else {
            handleDisconnect()
            return
        }

        // Read transport type
        var transportType: UInt32 = 0
        var transportAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transportSize = UInt32(MemoryLayout<UInt32>.size)
        let transportStatus = AudioObjectGetPropertyData(
            defaultDeviceID,
            &transportAddress,
            0,
            nil,
            &transportSize,
            &transportType
        )

        guard transportStatus == noErr,
              transportType == kAudioDeviceTransportTypeBluetooth ||
              transportType == kAudioDeviceTransportTypeBluetoothLE
        else {
            handleDisconnect()
            return
        }

        // Read device name
        var nameRef: CFString = "" as CFString
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var nameSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(defaultDeviceID, &nameAddress, 0, nil, &nameSize, &nameRef)
        let deviceName = nameRef as String

        // Read device UID
        var uidRef: CFString = "" as CFString
        var uidAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uidSize = UInt32(MemoryLayout<CFString>.size)
        AudioObjectGetPropertyData(defaultDeviceID, &uidAddress, 0, nil, &uidSize, &uidRef)
        let deviceUID = uidRef as String

        guard !deviceName.isEmpty, !deviceUID.isEmpty else {
            handleDisconnect()
            return
        }

        let deviceType = classifyDeviceType(name: deviceName)
        let batteryInfo = queryIORegistryBattery(forDeviceName: deviceName)

        var newDevice = BluetoothAudioDevice(
            id: deviceUID,
            name: deviceName,
            batteryLevel: batteryInfo.device,
            caseBatteryLevel: batteryInfo.caseBattery,
            isCharging: false,
            isConnected: true,
            deviceType: deviceType
        )

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let isNewDevice = self.previousActiveDeviceID != deviceUID
            // Preserve BLE-sourced case battery when re-detecting the same device
            // (IOBluetooth returns 0 sentinel when case lid is closed)
            if !isNewDevice,
               newDevice.caseBatteryLevel <= 0,
               let existingCase = self.activeDevice?.caseBatteryLevel,
               existingCase > 0 {
                newDevice.caseBatteryLevel = existingCase
            }
            self.activeDevice = newDevice
            if isNewDevice {
                self.previousActiveDeviceID = deviceUID
                // Kick off BLE scan to pick up AirPods proximity-pairing advertisements
                // which carry case battery level (Apple Continuity Protocol type 0x07)
                self.bleCaseBattery = -1
                self.bleLeftBattery = -1
                self.bleRightBattery = -1
                self.startBLEScanning()
                if Defaults[.showBluetoothNotifications] {
                    if batteryInfo.device >= 0 {
                        self.coordinator.toggleExpandingView(status: true, type: .bluetooth)
                    } else {
                        self.retryBatteryThenNotify(deviceName: deviceName)
                    }
                }
            }
        }
    }

    private func retryBatteryThenNotify(deviceName: String) {
        batteryRetryTask?.cancel()
        batteryRetryTask = Task { [weak self] in
            for _ in 0..<5 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.refreshBatteryFromIORegistry()
                if let level = self?.activeDevice?.batteryLevel, level >= 0 {
                    break
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if Defaults[.showBluetoothNotifications] {
                    self.coordinator.toggleExpandingView(status: true, type: .bluetooth)
                }
            }
        }
    }

    private func handleDisconnect() {
        guard previousActiveDeviceID != nil else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.activeDevice = nil
            self.previousActiveDeviceID = nil
        }
    }

    // MARK: - Device Type Classification

    private func classifyDeviceType(name: String) -> BluetoothDeviceType {
        let lower = name.lowercased()
        if lower.contains("airpods max") {
            return .airPodsMax
        } else if lower.contains("airpods pro") {
            return .airPodsPro2
        } else if lower.contains("airpods") {
            return .airPods3
        } else if lower.contains("beats") {
            return .beats
        } else {
            return .genericHeadphones
        }
    }

    // MARK: - IORegistry Battery (Layer 2)

    func refreshBatteryFromIORegistry() {
        guard let device = activeDevice else { return }
        let info = queryIORegistryBattery(forDeviceName: device.name)
        DispatchQueue.main.async { [weak self] in
            if info.device >= 0 {
                self?.activeDevice?.batteryLevel = info.device
            }
            // Only overwrite case from IORegistry if it reports a real value (> 0).
            // IOBluetooth returns 0 as sentinel when case lid is closed;
            // BLE advertisement may already have a valid value we must preserve.
            if info.caseBattery > 0 {
                self?.activeDevice?.caseBatteryLevel = info.caseBattery
            }
        }
    }

    private struct BluetoothBatteryInfo {
        var device: Int = -1
        var caseBattery: Int = -1
    }

    private func queryIORegistryBattery(forDeviceName deviceName: String) -> BluetoothBatteryInfo {
        // Primary: AppleDeviceManagementHIDEventService
        let hidResult = batteryFromHIDEventService(deviceName: deviceName)
        if hidResult.device >= 0 {
            return hidResult
        }
        // Secondary fallback: direct IOBluetoothDevice battery selectors
        let ioBluetoothResult = batteryFromConnectedIOBluetoothDevice(deviceName: deviceName)
        if ioBluetoothResult.device >= 0 {
            return ioBluetoothResult
        }
        // Fallback: IOPowerSources (device battery only)
        let psBattery = batteryFromPowerSources(deviceName: deviceName)
        return BluetoothBatteryInfo(
            device: psBattery,
            caseBattery: max(hidResult.caseBattery, ioBluetoothResult.caseBattery)
        )
    }

    private func batteryFromConnectedIOBluetoothDevice(deviceName: String) -> BluetoothBatteryInfo {
        var result = BluetoothBatteryInfo()
        let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        let recentDevices = IOBluetoothDevice.recentDevices(32) as? [IOBluetoothDevice] ?? []
        let devices = pairedDevices + recentDevices
        guard !devices.isEmpty else {
            return result
        }

        let target = normalizeDeviceName(deviceName)
        for device in devices where device.isConnected() {
            let candidateName = device.name ?? device.addressString ?? ""
            let normalized = normalizeDeviceName(candidateName)
            let matches = normalized.contains(target) || target.contains(normalized)
            guard matches else { continue }

            let single = batteryValue(from: device, keys: [
                "batteryPercentSingle",
                "batteryPercent",
                "BatteryPercent",
            ])
            let left = batteryValue(from: device, keys: [
                "batteryPercentLeft",
                "BatteryPercentLeft",
            ])
            let right = batteryValue(from: device, keys: [
                "batteryPercentRight",
                "BatteryPercentRight",
            ])
            let caseLevel = batteryValue(from: device, keys: [
                "batteryPercentCase",
                "BatteryPercentCase",
                "caseBatteryPercent",
                "CaseBatteryPercent",
            ])
            if let left, let right {
                result.device = max(0, min(100, (left + right) / 2))
            } else if let left {
                result.device = left
            } else if let right {
                result.device = right
            } else if let single, (0...100).contains(single) {
                result.device = single
            }

            if let caseLevel, (0...100).contains(caseLevel) {
                result.caseBattery = caseLevel
            }
            if result.device >= 0 {
                return result
            }
        }
        return result
    }

    private func normalizeDeviceName(_ name: String) -> String {
        let lowered = name.lowercased()
        let scalars = lowered.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(scalars))
    }

    private func batteryValue(from device: IOBluetoothDevice, keys: [String]) -> Int? {
        for key in keys {
            let sel = NSSelectorFromString(key)
            guard device.responds(to: sel) else { continue }
            if let number = device.value(forKey: key) as? NSNumber {
                let value = number.intValue
                if (0...100).contains(value) { return value }
            }
        }
        return nil
    }

    private func batteryFromHIDEventService(deviceName: String) -> BluetoothBatteryInfo {
        var result = BluetoothBatteryInfo()
        var iterator: io_iterator_t = 0
        let matchingDict = IOServiceMatching("AppleDeviceManagementHIDEventService")
        let kr = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            matchingDict,
            &iterator
        )
        guard kr == KERN_SUCCESS else { return result }
        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            var propertiesRef: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(
                service,
                &propertiesRef,
                kCFAllocatorDefault,
                0
            )
            guard propResult == KERN_SUCCESS, let properties = propertiesRef?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            guard let transport = properties["Transport"] as? String,
                  transport == "Bluetooth" else {
                continue
            }

            // Verify the device name matches (partial, case-insensitive)
            if let product = properties["Product"] as? String {
                let nameMatches = product.lowercased().contains(deviceName.lowercased())
                    || deviceName.lowercased().contains(product.lowercased())
                guard nameMatches else { continue }
            }

            #if DEBUG
            print("\u{1F50B} IORegistry Bluetooth device properties: \(properties.keys.sorted())")
            #endif

            if let batteryPercent = properties["BatteryPercent"] as? Int {
                result.device = batteryPercent
            }

            // Try common case battery key names
            if let caseBattery = properties["BatteryPercentCase"] as? Int {
                result.caseBattery = caseBattery
            } else if let caseBattery = properties["CaseBatteryPercent"] as? Int {
                result.caseBattery = caseBattery
            } else if let caseBattery = properties["BatteryPercent-Case"] as? Int {
                result.caseBattery = caseBattery
            }

            if result.device >= 0 {
                return result
            }
        }
        return result
    }

    private func batteryFromPowerSources(deviceName: String) -> Int {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef]
        else { return -1 }

        for source in sources {
            guard let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any]
            else { continue }

            guard let transport = info["Transport Type"] as? String,
                  transport.lowercased().contains("bluetooth") else { continue }

            if let name = info[kIOPSNameKey] as? String {
                let nameMatches = name.lowercased().contains(deviceName.lowercased())
                    || deviceName.lowercased().contains(name.lowercased())
                guard nameMatches else { continue }
            }

            if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                return capacity
            }
        }
        return -1
    }

    // MARK: - IOBluetooth Notifications (Layer 4, non-sandbox only)

    private func registerIOBluetoothNotifications() {
        iOBluetoothConnectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(bluetoothDeviceConnected(_:device:))
        )
    }

    @objc private func bluetoothDeviceConnected(
        _ notification: IOBluetoothUserNotification,
        device: IOBluetoothDevice
    ) {
        refreshActiveAudioDevice()
    }

    // MARK: - Battery Color Utility

    func batteryColor(for level: Int, charging: Bool) -> Color {
        if charging { return .green }
        if level < 0 { return .gray }
        if level <= 20 { return .red }
        if level <= 40 { return .yellow }
        return .green
    }

}

// MARK: - CBCentralManagerDelegate (Layer 3)

extension BluetoothDeviceManager: CBCentralManagerDelegate {

    /// Initialises Core Bluetooth on demand for BLE device identification.
    /// Call this only when BLE scanning is actually needed; it will trigger
    /// the Bluetooth permission prompt on first use.
    func startBLEScanning() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: .global(qos: .background))
        } else if centralManager?.state == .poweredOn {
            // Restart scan to pick up fresh advertisements
            centralManager?.stopScan()
            centralManager?.scanForPeripherals(withServices: nil, options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true
            ])
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 15) { [weak self] in
                self?.centralManager?.stopScan()
            }
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        // Allow duplicates so we keep receiving updated battery advertisements
        central.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        // Stop after 15 seconds; caller can re-trigger via startBLEScanning()
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.centralManager?.stopScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        // Parse Apple Continuity manufacturer data (Company ID 0x004C)
        guard let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data,
              manufacturerData.count >= 2 else { return }

        let companyID = UInt16(manufacturerData[0]) | (UInt16(manufacturerData[1]) << 8)
        guard companyID == 0x004C else { return }

        // AirPods Proximity Pairing message: type byte at index 2 = 0x07
        if manufacturerData.count >= 10, manufacturerData[2] == 0x07 {
            // AirPods Pro 2 shifted layout: extra status byte at [7] pushes battery forward
            // Index 8: earbuds — high nibble = right, low nibble = left (0-10 scale)
            let rightNibble = Int((manufacturerData[8] >> 4) & 0x0F)
            let leftNibble  = Int(manufacturerData[8] & 0x0F)
            // Index 9: high nibble = case battery (0-10 scale), low nibble = charging flags
            let caseNibble  = Int((manufacturerData[9] >> 4) & 0x0F)

            let right = (0...10).contains(rightNibble) ? rightNibble * 10 : -1
            let left  = (0...10).contains(leftNibble)  ? leftNibble  * 10 : -1
            let caseB = (0...10).contains(caseNibble)  ? caseNibble  * 10 : -1

            if right >= 0 { bleRightBattery = right }
            if left  >= 0 { bleLeftBattery  = left  }
            if caseB >= 0 { bleCaseBattery  = caseB }

            // Update active device battery from BLE if this matches
            if let activeDevice = activeDevice {
                let peripheralName = peripheral.name ?? ""
                let target = normalizeDeviceName(activeDevice.name)
                let normalized = normalizeDeviceName(peripheralName)
                if normalized.contains(target) || target.contains(normalized) || peripheralName.isEmpty {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if caseB >= 0 {
                            self.activeDevice?.caseBatteryLevel = caseB
                        }
                    }
                    let refined = classifyDeviceType(name: peripheralName.isEmpty ? activeDevice.name : peripheralName)
                    DispatchQueue.main.async { [weak self] in
                        self?.activeDevice?.deviceType = refined
                    }
                }
            }
        } else {
            // Non-proximity-pairing Apple ad — still update device type if name matches
            guard let activeDevice = activeDevice,
                  let peripheralName = peripheral.name,
                  peripheralName.lowercased().contains(activeDevice.name.lowercased())
                    || activeDevice.name.lowercased().contains(peripheralName.lowercased())
            else { return }
            let refined = classifyDeviceType(name: peripheralName)
            DispatchQueue.main.async { [weak self] in
                self?.activeDevice?.deviceType = refined
            }
        }
    }
}
