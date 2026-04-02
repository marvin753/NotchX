//
//  ConnectivitySettingsPage.swift
//  NotchX
//

import Defaults
import SwiftUI

struct ConnectivitySettings: View {
    @ObservedObject var deviceManager = BluetoothDeviceManager.shared

    var body: some View {
        Form {
            Section {
                NXStyledToggle(title: "Show Bluetooth indicator in notch", key: .showBluetoothIndicator)
                NXStyledToggle(title: "Show connection notifications", key: .showBluetoothNotifications)
            } header: {
                NXSectionHeader(title: "General")
            }

            Section {
                if let device = deviceManager.activeDevice {
                    BluetoothDeviceRow(device: device)
                } else {
                    HStack {
                        Image(systemName: "headphones")
                            .font(.title2)
                            .foregroundStyle(.gray)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Bluetooth audio device")
                                .font(.headline)
                            Text("Connect a device to see it here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                NXSectionHeader(title: "Active Device")
            }

            Section {
                Button {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text("Open Bluetooth Settings")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                NXSectionHeader(title: "System")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Tip: Disable native Bluetooth popups", systemImage: "lightbulb")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("To only see connection notifications in NotchX, disable the system popup in **System Settings \u{2192} Notifications \u{2192} Bluetooth**.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Text("Open Notification Settings")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
                .padding(.vertical, 4)
            } header: {
                NXSectionHeader(title: "System Notifications")
            }
        }
        .formStyle(.grouped)
        .accentColor(.effectiveAccent)
        .navigationTitle("Connectivity")
    }
}

struct BluetoothDeviceRow: View {
    let device: BluetoothAudioDevice
    @ObservedObject var deviceManager = BluetoothDeviceManager.shared

    var body: some View {
        HStack {
            Image(systemName: device.sfSymbol)
                .font(.title2)
                .foregroundStyle(device.isConnected ? .white : .gray)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Circle()
                .fill(device.isConnected ? .green : .gray)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private var statusText: String {
        if !device.isConnected { return String(localized: "Not Connected") }
        if device.batteryLevel >= 0 { return "\(device.batteryLevel)%" }
        return String(localized: "Connected")
    }
}
