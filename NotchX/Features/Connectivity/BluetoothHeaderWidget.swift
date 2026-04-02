//
//  BluetoothHeaderWidget.swift
//  NotchX
//

import Defaults
import SwiftUI

struct BluetoothHeaderWidget: View {
    @ObservedObject var deviceManager = BluetoothDeviceManager.shared
    @EnvironmentObject var vm: NotchXViewModel
    @State private var showDetail = false

    var body: some View {
        if let device = deviceManager.activeDevice, device.isConnected,
           Defaults[.showBluetoothIndicator]
        {
            Button {
                showDetail.toggle()
            } label: {
                ZStack {
                    // Track ring (background)
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 3)
                        .frame(width: 26, height: 26)

                    // Battery ring (foreground)
                    if device.batteryLevel >= 0 {
                        Circle()
                            .trim(from: 0, to: fillAmount(for: device.batteryLevel))
                            .stroke(
                                ringColor(for: device.batteryLevel),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 26, height: 26)
                            .rotationEffect(.degrees(-90))
                    }

                    // Device icon
                    Image(systemName: device.sfSymbol)
                        .foregroundColor(.white)
                        .imageScale(.small)
                        .font(.system(size: 11))
                }
                .frame(width: 30, height: 30)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $showDetail, arrowEdge: .bottom) {
                BluetoothDeviceDetailPopover(device: device)
            }
            .onChange(of: showDetail) {
                vm.isBluetoothPopoverActive = showDetail
            }
            .onAppear {
                BluetoothDeviceManager.shared.refreshBatteryFromIORegistry()
            }
        }
    }

    private func fillAmount(for level: Int) -> CGFloat {
        max(0, min(1, CGFloat(level) / 100.0))
    }

    private func ringColor(for level: Int) -> Color {
        if level <= 20 { return .red }
        if level <= 50 { return .yellow }
        return .green
    }
}

// MARK: - Detail Popover

struct BluetoothDeviceDetailPopover: View {
    let device: BluetoothAudioDevice
    @ObservedObject var deviceManager = BluetoothDeviceManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: device.sfSymbol)
                    .font(.title)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(device.isConnected ? String(localized: "Connected") : String(localized: "Disconnected"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()
                .background(.gray.opacity(0.3))

            // Battery rows
            VStack(alignment: .leading, spacing: 8) {
                BatteryRow(
                    label: deviceLabel,
                    level: device.batteryLevel,
                    color: deviceManager.batteryColor(for: device.batteryLevel, charging: device.isCharging)
                )

                if device.caseBatteryLevel >= 0 {
                    BatteryRow(
                        label: String(localized: "Case"),
                        level: device.caseBatteryLevel,
                        color: deviceManager.batteryColor(for: device.caseBatteryLevel, charging: false)
                    )
                }
            }

            Divider()
                .background(.gray.opacity(0.3))

            // Settings link
            Button {
                if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack {
                    Text("Bluetooth Settings")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "arrow.up.forward")
                        .font(.caption)
                }
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 220)
        .background(.black)
    }

    private var deviceLabel: String {
        switch device.deviceType {
        case .airPods1, .airPods2, .airPods3, .airPods4:
            return "AirPods"
        case .airPodsPro, .airPodsPro2:
            return "AirPods"
        case .airPodsMax:
            return "AirPods Max"
        case .beats:
            return "Headphones"
        case .genericHeadphones:
            return "Headphones"
        case .genericSpeaker:
            return "Speaker"
        }
    }
}

private struct BatteryRow: View {
    let label: String
    let level: Int
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: batteryIcon)
                .foregroundStyle(color)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
            if level >= 0 {
                Text("\(level)%")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white)
            } else {
                Text("\u{2013}")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var batteryIcon: String {
        guard level >= 0 else { return "battery.0percent" }
        if level >= 75 { return "battery.100percent" }
        if level >= 50 { return "battery.75percent" }
        if level >= 25 { return "battery.50percent" }
        return "battery.25percent"
    }
}
