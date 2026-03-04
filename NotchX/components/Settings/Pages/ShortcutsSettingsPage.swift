//
//  ShortcutsSettingsPage.swift
//  NotchX
//

import KeyboardShortcuts
import SwiftUI

struct Shortcuts: View {
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder("Toggle Sneak Peek:", name: .toggleSneakPeek)
            } header: {
                NXSectionHeader(title: "Media")
            } footer: {
                Text("Sneak Peek shows the media title and artist under the notch for a few seconds.")
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }

            Section {
                KeyboardShortcuts.Recorder("Toggle Notch Open:", name: .toggleNotchOpen)
            } header: {
                NXSectionHeader(title: "Notch")
            }
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Shortcuts")
    }
}
