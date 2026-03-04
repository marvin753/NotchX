//
//  SettingsView.swift
//  NotchX
//
//  Created by Richard Kunkli on 07/08/2024.
//

import Defaults
import Sparkle
import SwiftUI

struct SettingsView: View {
    @State private var selectedTab = "General"
    @State private var accentColorUpdateTrigger = UUID()

    let updaterController: SPUStandardUpdaterController?

    init(updaterController: SPUStandardUpdaterController? = nil) {
        self.updaterController = updaterController
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: "General") {
                    SettingsSidebarLabel(title: "General", icon: "gear", color: .gray)
                }

                Section("Notifications") {
                    NavigationLink(value: "Battery") {
                        SettingsSidebarLabel(title: "Battery", icon: "bolt.fill", color: .orange)
                    }
                    NavigationLink(value: "Sound") {
                        SettingsSidebarLabel(title: "Sound", icon: "speaker.wave.3", color: .blue)
                    }
                    NavigationLink(value: "Display") {
                        SettingsSidebarLabel(title: "Display", icon: "sun.max.fill", color: .cyan)
                    }
                    NavigationLink(value: "Focus") {
                        SettingsSidebarLabel(title: "Focus", icon: "moon.fill", color: .indigo, isComingSoon: true)
                    }
                }

                Section("Live Activities") {
                    NavigationLink(value: "NowPlaying") {
                        SettingsSidebarLabel(title: "Now Playing", icon: "play.fill", color: .pink)
                    }
                    NavigationLink(value: "Calendar") {
                        SettingsSidebarLabel(title: "Calendar", icon: "calendar", color: .red)
                    }
                    NavigationLink(value: "Teleprompter") {
                        SettingsSidebarLabel(title: "Teleprompter", icon: "text.word.spacing", color: .mint)
                    }
                }

                Section("Appearance") {
                    NavigationLink(value: "Darstellung") {
                        SettingsSidebarLabel(title: "Darstellung", icon: "eye.fill", color: .purple)
                    }
                    NavigationLink(value: "Shelf") {
                        SettingsSidebarLabel(title: "Shelf", icon: "books.vertical", color: .teal)
                    }
                }

                Section("System") {
                    NavigationLink(value: "Shortcuts") {
                        SettingsSidebarLabel(title: "Shortcuts", icon: "keyboard", color: .gray)
                    }
                    NavigationLink(value: "Advanced") {
                        SettingsSidebarLabel(title: "Advanced", icon: "gearshape.2.fill", color: .gray)
                    }
                    NavigationLink(value: "LockScreen") {
                        SettingsSidebarLabel(title: "Lock Screen", icon: "lock.fill", color: Color(white: 0.35), isComingSoon: true)
                    }
                    NavigationLink(value: "About") {
                        SettingsSidebarLabel(title: "About", icon: "info.circle.fill", color: .blue)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .tint(.effectiveAccent)
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(200)
        } detail: {
            Group {
                switch selectedTab {
                case "General":
                    GeneralSettings()
                case "Battery":
                    Charge()
                case "Sound":
                    HUDSettingsPage(pageTitle: "Sound", pageDescription: "Configure how volume changes appear in the notch.")
                case "Display":
                    HUDSettingsPage(pageTitle: "Display", pageDescription: "Configure how brightness changes appear in the notch.")
                case "Focus":
                    ComingSoonPlaceholder(icon: "moon.fill", title: "Focus", description: "Focus mode integration and Do Not Disturb controls are coming soon.")
                case "NowPlaying":
                    NowPlayingSettings()
                case "Calendar":
                    CalendarSettings()
                case "Teleprompter":
                    TeleprompterSettingsView()
                case "Darstellung":
                    Darstellung()
                case "Shelf":
                    Shelf()
                case "Shortcuts":
                    Shortcuts()
                case "Advanced":
                    Advanced()
                case "LockScreen":
                    ComingSoonPlaceholder(icon: "lock.fill", title: "Lock Screen", description: "Lock screen customization options are coming in a future release.")
                case "About":
                    if let controller = updaterController {
                        About(updaterController: controller)
                    } else {
                        About(
                            updaterController: SPUStandardUpdaterController(
                                startingUpdater: false, updaterDelegate: nil,
                                userDriverDelegate: nil))
                    }
                default:
                    GeneralSettings()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar(removing: .sidebarToggle)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 700)
        .background(.ultraThinMaterial)
        .tint(.effectiveAccent)
        .id(accentColorUpdateTrigger)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AccentColorChanged"))) { _ in
            accentColorUpdateTrigger = UUID()
        }
    }
}

#Preview("Settings View") {
    SettingsView(updaterController: SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: nil
    ))
    .frame(width: 700, height: 600)
}
