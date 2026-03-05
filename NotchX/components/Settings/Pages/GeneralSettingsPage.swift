//
//  GeneralSettingsPage.swift
//  NotchX
//
//  General settings page redesigned with the NX design system.
//  Extracted from SettingsView.swift's `GeneralSettings` struct.
//

import Defaults
import LaunchAtLogin
import SwiftUI

struct GeneralSettings: View {

    // MARK: - State

    @State private var screens: [(uuid: String, name: String)] = NSScreen.screens.compactMap { screen in
        guard let uuid = screen.displayUUID else { return nil }
        return (uuid, screen.localizedName)
    }

    // MARK: - Dependencies

    @EnvironmentObject var vm: NotchXViewModel
    @ObservedObject var coordinator = NotchXViewCoordinator.shared

    // MARK: - Defaults

    @Default(.gestureSensitivity) var gestureSensitivity
    @Default(.nonNotchHeight) var nonNotchHeight
    @Default(.nonNotchHeightMode) var nonNotchHeightMode
    @Default(.notchHeight) var notchHeight
    @Default(.notchHeightMode) var notchHeightMode
    @Default(.showOnAllDisplays) var showOnAllDisplays
    @Default(.automaticallySwitchDisplay) var automaticallySwitchDisplay

    // MARK: - Body

    var body: some View {
        Form {
            systemFeaturesSection
            notchSizingSection
            notchBehaviourSection
            gestureControlsSection
        }
        .toolbar {
            Button("Quit app") { NSApp.terminate(self) }
                .controlSize(.extraLarge)
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("General")
    }

    // MARK: - System Features

    @ViewBuilder
    private var systemFeaturesSection: some View {
        Section {
            NXStyledToggleBinding(
                title: "Show menu bar icon",
                isOn: Binding(
                    get: { Defaults[.menubarIcon] },
                    set: { Defaults[.menubarIcon] = $0 }
                )
            )

            NXStyledToggleBinding(
                title: "Launch at login",
                isOn: Binding(
                    get: { LaunchAtLogin.isEnabled },
                    set: { LaunchAtLogin.isEnabled = $0 }
                )
            )

            NXStyledToggle(title: "Show on all displays", key: .showOnAllDisplays)
                .onChange(of: showOnAllDisplays) {
                    NotificationCenter.default.post(
                        name: Notification.Name.showOnAllDisplaysChanged,
                        object: nil
                    )
                }

            VStack(alignment: .leading, spacing: 10) {
                Text("Preferred display")
                    .font(.body)

                if screens.isEmpty {
                    NXVisualPreviewPicker(
                        items: [
                            NXPreviewItem(label: "No display detected", value: "" as String, icon: "display.trianglebadge.exclamationmark"),
                        ],
                        selection: .constant("")
                    )
                    .disabled(true)
                } else {
                    NXVisualPreviewPicker(
                        items: screens.enumerated().map { index, screen in
                            NXPreviewItem(label: screen.name, value: screen.uuid, icon: index == 0 ? "macbook" : "display")
                        },
                        selection: Binding(
                            get: {
                                if let uuid = coordinator.preferredScreenUUID,
                                   screens.contains(where: { $0.uuid == uuid }) {
                                    return uuid
                                }
                                return screens.first?.uuid ?? ""
                            },
                            set: { newValue in
                                coordinator.preferredScreenUUID = newValue
                            }
                        )
                    )
                }
            }
            .onChange(of: NSScreen.screens) {
                screens = NSScreen.screens.compactMap { screen in
                    guard let uuid = screen.displayUUID else { return nil }
                    return (uuid, screen.localizedName)
                }
                // Fallback: validate current selection
                if let current = coordinator.preferredScreenUUID,
                   !screens.contains(where: { $0.uuid == current }),
                   let firstUUID = screens.first?.uuid {
                    coordinator.preferredScreenUUID = firstUUID
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                screens = NSScreen.screens.compactMap { screen in
                    guard let uuid = screen.displayUUID else { return nil }
                    return (uuid, screen.localizedName)
                }
                if let current = coordinator.preferredScreenUUID,
                   !screens.contains(where: { $0.uuid == current }),
                   let firstUUID = screens.first?.uuid {
                    coordinator.preferredScreenUUID = firstUUID
                }
            }
            .disabled(showOnAllDisplays)

            NXStyledToggle(title: "Automatically switch displays", key: .automaticallySwitchDisplay)
                .onChange(of: automaticallySwitchDisplay) {
                    NotificationCenter.default.post(
                        name: Notification.Name.automaticallySwitchDisplayChanged,
                        object: nil
                    )
                }
                .disabled(showOnAllDisplays)
        } header: {
            NXSectionHeader(title: "System features")
        }
    }

    // MARK: - Notch Sizing

    @ViewBuilder
    private var notchSizingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Notch height on notch displays")
                    .font(.body)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "Match notch", value: WindowHeightMode.matchRealNotchSize) {
                            NotchSizingMatchNotchIcon()
                        },
                        NXPreviewItem(label: "Match menu bar", value: WindowHeightMode.matchMenuBar) {
                            NotchSizingMatchMenuBarIcon()
                        },
                        NXPreviewItem(label: "Custom", value: WindowHeightMode.custom) {
                            NotchSizingCustomIcon()
                        },
                    ],
                    selection: $notchHeightMode
                )
                .onChange(of: notchHeightMode) {
                    switch notchHeightMode {
                    case .matchRealNotchSize: notchHeight = 38
                    case .matchMenuBar: notchHeight = 44
                    case .custom: notchHeight = 28
                    }
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged,
                        object: nil
                    )
                }
            }

            if notchHeightMode == .custom {
                NXStyledSlider(
                    value: Binding(get: { Double(notchHeight) }, set: { notchHeight = CGFloat($0) }),
                    title: "Custom notch size",
                    range: 14...42,
                    step: 1,
                    unit: " pt"
                )
                .onChange(of: notchHeight) {
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged,
                        object: nil
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.snappy(duration: 0.25), value: notchHeightMode)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Notch height on non-notch displays")
                    .font(.body)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "Match menu bar", value: WindowHeightMode.matchMenuBar) {
                            NotchSizingMatchMenuBarIcon()
                        },
                        NXPreviewItem(label: "Match notch", value: WindowHeightMode.matchRealNotchSize) {
                            NotchSizingMatchNotchIcon()
                        },
                        NXPreviewItem(label: "Custom", value: WindowHeightMode.custom) {
                            NotchSizingCustomIcon()
                        },
                    ],
                    selection: $nonNotchHeightMode
                )
                .onChange(of: nonNotchHeightMode) {
                    switch nonNotchHeightMode {
                    case .matchMenuBar: nonNotchHeight = 24
                    case .matchRealNotchSize: nonNotchHeight = 32
                    case .custom: nonNotchHeight = 28
                    }
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged,
                        object: nil
                    )
                }
            }

            if nonNotchHeightMode == .custom {
                NXStyledSlider(
                    value: Binding(get: { Double(nonNotchHeight) }, set: { nonNotchHeight = CGFloat($0) }),
                    title: "Custom notch size",
                    range: 14...42,
                    step: 1,
                    unit: " pt"
                )
                .onChange(of: nonNotchHeight) {
                    NotificationCenter.default.post(
                        name: Notification.Name.notchHeightChanged,
                        object: nil
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.snappy(duration: 0.25), value: nonNotchHeightMode)
            }
        } header: {
            NXSectionHeader(title: "Notch sizing")
        }
    }

    // MARK: - Notch Behaviour

    @ViewBuilder
    private var notchBehaviourSection: some View {
        Section {
            NXStyledToggle(title: "Enable haptic feedback", key: .enableHaptics)

            NXStyledToggleBinding(
                title: "Remember last tab",
                isOn: $coordinator.openLastTabByDefault
            )
        } header: {
            NXSectionHeader(title: "Notch behavior")
        }
    }

    // MARK: - Gesture Controls

    @ViewBuilder
    private var gestureControlsSection: some View {
        Section {
            // Horizontal media gestures — not yet implemented
            NXStyledToggleBinding(
                title: "Change media with horizontal gestures",
                isOn: .constant(false),
                isDisabled: true
            )

            NXStyledToggle(title: "Close gesture", key: .closeGestureEnabled)

            VStack(alignment: .leading, spacing: 10) {
                Text("Gesture sensitivity")
                    .font(.body)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "High", value: 100.0, icon: "hare"),
                        NXPreviewItem(label: "Medium", value: 200.0, icon: "figure.walk"),
                        NXPreviewItem(label: "Low", value: 300.0, icon: "tortoise"),
                    ],
                    selection: Binding(
                        get: { gestureSensitivity },
                        set: { gestureSensitivity = $0 }
                    ),
                    cardHeight: 60,
                    iconSize: 22
                )
            }
        } header: {
            NXSectionHeader(title: "Gesture control")
        } footer: {
            Text("Two-finger swipe up on notch to close, two-finger swipe down on notch to open")
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
    }
}

// MARK: - Notch Sizing Canvas Icons

// Shared geometry constants for all notch sizing icons.
private let _shellX: CGFloat = 4
private let _shellY: CGFloat = 5
private let _shellW: CGFloat = 112
private let _shellH: CGFloat = 44
private let _shellCR: CGFloat = 11
private let _notchW: CGFloat = 36
private let _notchCR: CGFloat = 5

/// Display shell path — top corners rounded, bottom edge left open (sharp corners).
private func displayShellPath() -> Path {
    var p = Path()
    p.move(to: CGPoint(x: _shellX, y: _shellY + _shellH))
    p.addLine(to: CGPoint(x: _shellX, y: _shellY + _shellCR))
    p.addArc(
        tangent1End: CGPoint(x: _shellX, y: _shellY),
        tangent2End: CGPoint(x: _shellX + _shellCR, y: _shellY),
        radius: _shellCR
    )
    p.addLine(to: CGPoint(x: _shellX + _shellW - _shellCR, y: _shellY))
    p.addArc(
        tangent1End: CGPoint(x: _shellX + _shellW, y: _shellY),
        tangent2End: CGPoint(x: _shellX + _shellW, y: _shellY + _shellCR),
        radius: _shellCR
    )
    p.addLine(to: CGPoint(x: _shellX + _shellW, y: _shellY + _shellH))
    p.closeSubpath()
    return p
}

/// Notch path anchored at the display top edge (y = _shellY), centered in canvas.
private func notchPath(canvasWidth: CGFloat, height notchH: CGFloat) -> Path {
    let x = (canvasWidth - _notchW) / 2
    let topY = _shellY
    var p = Path()
    p.move(to: CGPoint(x: x, y: topY))
    p.addLine(to: CGPoint(x: x, y: topY + notchH - _notchCR))
    p.addArc(
        tangent1End: CGPoint(x: x, y: topY + notchH),
        tangent2End: CGPoint(x: x + _notchCR, y: topY + notchH),
        radius: _notchCR
    )
    p.addLine(to: CGPoint(x: x + _notchW - _notchCR, y: topY + notchH))
    p.addArc(
        tangent1End: CGPoint(x: x + _notchW, y: topY + notchH),
        tangent2End: CGPoint(x: x + _notchW, y: topY + notchH - _notchCR),
        radius: _notchCR
    )
    p.addLine(to: CGPoint(x: x + _notchW, y: topY))
    p.closeSubpath()
    return p
}

/// Draws the display shell (fill + stroke) into a Canvas context.
private func drawShell(in context: GraphicsContext) {
    let shell = displayShellPath()
    context.fill(shell, with: .color(Color.primary.opacity(0.09)))
    context.stroke(shell, with: .color(Color.primary.opacity(0.14)), lineWidth: 1)
}

/// Menu bar zone path — matches display shell width, top corners rounded, bottom sharp.
private func menuBarZonePath() -> Path {
    let zoneH: CGFloat = 22
    var p = Path()
    p.move(to: CGPoint(x: _shellX, y: _shellY + zoneH))
    p.addLine(to: CGPoint(x: _shellX, y: _shellY + _shellCR))
    p.addArc(
        tangent1End: CGPoint(x: _shellX, y: _shellY),
        tangent2End: CGPoint(x: _shellX + _shellCR, y: _shellY),
        radius: _shellCR
    )
    p.addLine(to: CGPoint(x: _shellX + _shellW - _shellCR, y: _shellY))
    p.addArc(
        tangent1End: CGPoint(x: _shellX + _shellW, y: _shellY),
        tangent2End: CGPoint(x: _shellX + _shellW, y: _shellY + _shellCR),
        radius: _shellCR
    )
    p.addLine(to: CGPoint(x: _shellX + _shellW, y: _shellY + zoneH))
    p.closeSubpath()
    return p
}

/// Icon 1 — display shell + short notch.
private struct NotchSizingMatchNotchIcon: View {
    var body: some View {
        Canvas { context, size in
            drawShell(in: context)
            context.fill(
                notchPath(canvasWidth: size.width, height: 12),
                with: .color(Color.primary.opacity(0.82))
            )
        }
        .frame(width: 120, height: 54)
    }
}

/// Icon 2 — display shell + menu bar zone + separator + tall notch.
private struct NotchSizingMatchMenuBarIcon: View {
    var body: some View {
        Canvas { context, size in
            drawShell(in: context)

            // Menu bar zone
            context.fill(menuBarZonePath(), with: .color(Color.primary.opacity(0.06)))

            // Menu bar bottom edge line
            let lineY = _shellY + 22
            context.fill(
                Path(CGRect(x: _shellX, y: lineY, width: _shellW, height: 1)),
                with: .color(Color.primary.opacity(0.16))
            )

            // Notch reaching to the line
            context.fill(
                notchPath(canvasWidth: size.width, height: 22),
                with: .color(Color.primary.opacity(0.82))
            )
        }
        .frame(width: 120, height: 54)
    }
}

/// Icon 3 — display shell + short notch + adjustability pill.
private struct NotchSizingCustomIcon: View {
    var body: some View {
        Canvas { context, size in
            drawShell(in: context)

            // Notch shape
            context.fill(
                notchPath(canvasWidth: size.width, height: 12),
                with: .color(Color.primary.opacity(0.82))
            )

            // Adjustability pill — 7 pt below notch bottom
            let pillW: CGFloat = 18
            let pillH: CGFloat = 3.5
            let pillX = (size.width - pillW) / 2
            let pillY = _shellY + 12 + 7
            context.fill(
                Path(
                    roundedRect: CGRect(x: pillX, y: pillY, width: pillW, height: pillH),
                    cornerRadius: 1.75
                ),
                with: .color(Color.primary.opacity(0.20))
            )
        }
        .frame(width: 120, height: 54)
    }
}

#Preview("General Settings") {
    GeneralSettings()
        .environmentObject(NotchXViewModel())
}

