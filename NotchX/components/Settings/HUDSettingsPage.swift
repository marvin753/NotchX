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
    @Default(.enableGradient) var enableGradient
    @Default(.optionKeyAction) var optionKeyAction
    @Default(.hudReplacement) var hudReplacement
    @ObservedObject var coordinator = NotchXViewCoordinator.shared
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
                            NXPreviewItem(label: "Hierarchical", value: false) {
                                MiniBarHierarchical()
                                    .scaleEffect(2.6)
                                    .frame(width: 80, height: 50)
                                    .clipped()
                            },
                            NXPreviewItem(label: "Gradient", value: true) {
                                MiniBarGradient()
                                    .scaleEffect(2.6)
                                    .frame(width: 80, height: 50)
                                    .clipped()
                            },
                        ],
                        selection: $enableGradient
                    )
                }

                NXStyledToggle(title: "Enable glowing effect", key: .systemEventIndicatorShadow)

                NXStyledToggle(title: "Tint progress bar with accent color", key: .systemEventIndicatorUseAccent)
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
                                MiniHUDDefault()
                                    .scaleEffect(2.6)
                                    .frame(width: 80, height: 50)
                                    .clipped()
                            },
                            NXPreviewItem(label: "Inline", value: true) {
                                MiniHUDInline()
                                    .scaleEffect(2.6)
                                    .frame(width: 80, height: 50)
                                    .clipped()
                            },
                        ],
                        selection: $inlineHUD
                    )
                    .onChange(of: Defaults[.inlineHUD]) {
                        if Defaults[.inlineHUD] {
                            withAnimation {
                                Defaults[.systemEventIndicatorShadow] = false
                                Defaults[.enableGradient] = false
                            }
                        }
                    }
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

// MARK: - Mini-Preview: HUD Style

private struct MiniHUDDefault: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 7, weight: .medium))
            Capsule()
                .fill(Color.primary.opacity(0.5))
                .frame(width: 22, height: 4)
        }
        .frame(height: 18)
    }
}

private struct MiniHUDInline: View {
    var body: some View {
        Capsule()
            .fill(Color.primary.opacity(0.5))
            .frame(width: 28, height: 4)
            .frame(height: 18)
    }
}

// MARK: - Mini-Preview: Progress Bar Style

private struct MiniBarHierarchical: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 24, height: 5)
            Capsule()
                .fill(Color.primary.opacity(0.6))
                .frame(width: 14, height: 5)
        }
        .frame(height: 18)
    }
}

private struct MiniBarGradient: View {
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.primary.opacity(0.15))
                .frame(width: 24, height: 5)
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.effectiveAccent, Color.effectiveAccent.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 14, height: 5)
        }
        .frame(height: 18)
    }
}
