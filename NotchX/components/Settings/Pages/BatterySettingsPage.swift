//
//  BatterySettingsPage.swift
//  NotchX
//

import Defaults
import SwiftUI

struct Charge: View {
    var body: some View {
        Form {
            Section {
                NXStyledToggle(title: "Show battery indicator", key: .showBatteryIndicator)
                NXStyledToggle(title: "Show power status notifications", key: .showPowerStatusNotifications)
            } header: {
                NXSectionHeader(title: "General")
            }

            Section {
                NXStyledToggle(title: "Show battery percentage", key: .showBatteryPercentage)
                NXStyledToggle(title: "Show power status icons", key: .showPowerStatusIcons)
            } header: {
                NXSectionHeader(title: "Battery Information")
            }
        }
        .onAppear {
            Task { @MainActor in
                await XPCHelperClient.shared.isAccessibilityAuthorized()
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Battery")
    }
}
