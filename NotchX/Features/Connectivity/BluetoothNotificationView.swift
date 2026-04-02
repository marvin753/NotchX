//
//  BluetoothNotificationView.swift
//  NotchX
//

import SwiftUI

struct BluetoothConnectionNotification: View {
    @ObservedObject var deviceManager = BluetoothDeviceManager.shared
    @EnvironmentObject var vm: NotchXViewModel

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }

            Rectangle()
                .fill(.black)
                .frame(width: vm.closedNotchSize.width + 10)

            HStack(spacing: 4) {
                if let device = deviceManager.activeDevice, device.batteryLevel >= 0 {
                    Text("\(device.batteryLevel)%")
                        .font(.caption)
                        .foregroundStyle(
                            deviceManager.batteryColor(
                                for: device.batteryLevel,
                                charging: device.isCharging
                            )
                        )
                }
                Image(systemName: deviceManager.activeDevice?.sfSymbol ?? "headphones")
                    .foregroundStyle(.white)
                    .imageScale(.medium)
            }
            .frame(width: 76, alignment: .trailing)
        }
        .frame(height: vm.effectiveClosedNotchHeight, alignment: .center)
    }

    private var statusText: String {
        if let device = deviceManager.activeDevice, device.isConnected {
            return device.name
        }
        return String(localized: "Disconnected")
    }
}
