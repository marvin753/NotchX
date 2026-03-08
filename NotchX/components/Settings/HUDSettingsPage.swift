//
//  HUDSettingsPage.swift
//  NotchX
//

import Defaults
import SwiftUI

struct HUDSettingsPage: View {
    let pageTitle: String
    let pageDescription: String

    @EnvironmentObject var vm: NotchXViewModel
    @Default(.inlineHUD) var inlineHUD
    @Default(.progressBarStyle) var progressBarStyle
    @Default(.optionKeyAction) var optionKeyAction
    @Default(.hudReplacement) var hudReplacement
    // Removed @ObservedObject coordinator – it was never used but caused re-renders when
    // sneakPeek changed (volume/brightness at notch), leading to progress bar preview flicker.
    @State private var accessibilityAuthorized = false

    var body: some View {
        Form {
            // MARK: - Hero toggle

            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Replace system HUD")
                            .font(.headline)
                        Text(pageDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 40)
                    Defaults.Toggle("", key: .hudReplacement)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.large)
                        .disabled(!accessibilityAuthorized)
                }

                if !accessibilityAuthorized {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility access is required to replace the system HUD.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Button("Request Accessibility") {
                                XPCHelperClient.shared.requestAccessibilityAuthorization()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(.top, 6)
                }
            }

            // MARK: - General

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Option key behaviour")
                        .font(.body)

                    NXVisualPreviewPicker(
                        items: [
                            NXPreviewItem(label: "Settings", value: OptionKeyAction.openSettings, icon: "gearshape"),
                            NXPreviewItem(label: "Show HUD", value: OptionKeyAction.showHUD, icon: "dial.medium"),
                            NXPreviewItem(label: "None", value: OptionKeyAction.none, icon: "slash.circle"),
                        ],
                        selection: $optionKeyAction,
                        cardHeight: 60,
                        iconSize: 22
                    )
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Progress bar style")
                        .font(.body)

                    NXVisualPreviewPicker(
                        items: [
                            NXPreviewItem(label: "White", value: ProgressBarStyle.white) {
                                MiniNotchPreview { MiniBarWhite() }
                            },
                            NXPreviewItem(label: "Accent", value: ProgressBarStyle.accent) {
                                MiniNotchPreview { MiniBarAccent() }
                            },
                            NXPreviewItem(label: "Glow", value: ProgressBarStyle.glow) {
                                MiniNotchPreview { MiniBarGlow() }
                            },
                        ],
                        selection: $progressBarStyle
                    )
                    .onChange(of: progressBarStyle) { _, newValue in
                        if newValue == .glow {
                            withAnimation {
                                Defaults[.systemEventIndicatorShadow] = true
                            }
                        }
                    }
                }
            } header: {
                NXSectionHeader(title: "General")
            }
            .disabled(!hudReplacement)

            // MARK: - Open Notch

            Section {
                NXStyledToggle(title: "Show HUD in open notch", key: .showOpenNotchHUD)

                NXStyledToggle(title: "Show percentage", key: .showOpenNotchHUDPercentage)
                    .disabled(!Defaults[.showOpenNotchHUD])
            } header: {
                NXSectionHeader(title: "Open Notch", badge: "Beta")
            }
            .disabled(!hudReplacement)

            // MARK: - Closed Notch

            Section {
                VStack(alignment: .leading, spacing: 10) {
                    Text("HUD style")
                        .font(.body)

                    NXVisualPreviewPicker(
                        items: [
                            NXPreviewItem(label: "Default", value: false) {
                                AnimatedHUDDefaultPreview(isDisplayPage: pageTitle == "Display")
                            },
                            NXPreviewItem(label: "Inline", value: true) {
                                AnimatedHUDInlinePreview(isDisplayPage: pageTitle == "Display")
                            },
                        ],
                        selection: $inlineHUD,
                        cardHeight: 95
                    )
                }

                NXStyledToggle(title: "Show percentage", key: .showClosedNotchHUDPercentage)
            } header: {
                NXSectionHeader(title: "Closed Notch")
            }
            .disabled(!Defaults[.hudReplacement])
        }
        .accentColor(.effectiveAccent)
        .navigationTitle(pageTitle)
        .task {
            accessibilityAuthorized = await XPCHelperClient.shared.isAccessibilityAuthorized()
        }
        .onAppear {
            XPCHelperClient.shared.startMonitoringAccessibilityAuthorization()
        }
        .onDisappear {
            XPCHelperClient.shared.stopMonitoringAccessibilityAuthorization()
        }
        .onReceive(NotificationCenter.default.publisher(for: .accessibilityAuthorizationChanged)) { notification in
            if let granted = notification.userInfo?["granted"] as? Bool {
                accessibilityAuthorized = granted
            }
        }
    }
}

// MARK: - Mini-Preview: Progress Bar Style

private struct MiniNotchPreview<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .scaleEffect(2.6)
            .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
    }
}

private struct MiniBarWhite: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 24, height: 5)
            Capsule().fill(Color.white.opacity(0.9)).frame(width: 14, height: 5)
        }
        .frame(height: 18)
    }
}

private struct MiniBarAccent: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 24, height: 5)
            Capsule().fill(Color.effectiveAccent).frame(width: 14, height: 5)
        }
        .frame(height: 18)
    }
}

private struct MiniBarGlow: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.white.opacity(0.15)).frame(width: 24, height: 5)
            Capsule()
                .fill(LinearGradient(
                    colors: [Color.white, Color.white.opacity(0.3)],
                    startPoint: .leading, endPoint: .trailing
                ))
                .frame(width: 14, height: 5)
                .shadow(color: Color.white.opacity(0.6), radius: 3, x: 1)
        }
        .frame(height: 18)
    }
}
