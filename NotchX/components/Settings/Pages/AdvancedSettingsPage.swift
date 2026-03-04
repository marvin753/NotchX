//
//  AdvancedSettingsPage.swift
//  NotchX
//
//  Advanced settings page redesigned with the NX design system.
//  Extracted from SettingsView.swift's `Advanced` struct (lines 1281–1555)
//  and `AccentCircleButton` (lines 1557–1592).
//

import Defaults
import SwiftUI

// MARK: - Advanced

struct Advanced: View {

    // MARK: - Defaults

    @Default(.useCustomAccentColor) var useCustomAccentColor
    @Default(.customAccentColorData) var customAccentColorData
    @Default(.extendHoverArea) var extendHoverArea
    @Default(.showOnLockScreen) var showOnLockScreen
    @Default(.hideFromScreenRecording) var hideFromScreenRecording

    // MARK: - State

    @State private var customAccentColor: Color = Color.accentColor
    @State private var selectedPresetColor: PresetAccentColor? = nil

    let icons: [String] = ["logo2"]
    @State private var selectedIcon: String = "logo2"

    // MARK: - Preset Accent Colors

    enum PresetAccentColor: String, CaseIterable, Identifiable {
        case blue = "Blue"
        case purple = "Purple"
        case pink = "Pink"
        case red = "Red"
        case orange = "Orange"
        case yellow = "Yellow"
        case green = "Green"
        case graphite = "Graphite"

        var id: String { self.rawValue }

        var color: Color {
            switch self {
            case .blue:     return Color(red: 0.0,   green: 0.478, blue: 1.0)
            case .purple:   return Color(red: 0.686, green: 0.322, blue: 0.871)
            case .pink:     return Color(red: 1.0,   green: 0.176, blue: 0.333)
            case .red:      return Color(red: 1.0,   green: 0.271, blue: 0.227)
            case .orange:   return Color(red: 1.0,   green: 0.584, blue: 0.0)
            case .yellow:   return Color(red: 1.0,   green: 0.8,   blue: 0.0)
            case .green:    return Color(red: 0.4,   green: 0.824, blue: 0.176)
            case .graphite: return Color(red: 0.557, green: 0.557, blue: 0.576)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        Form {
            accentColorSection
            windowAppearanceSection
            appIconSection
            windowBehaviorSection
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Advanced")
        .onAppear { loadCustomColor() }
    }

    // MARK: - Accent Color Section

    @ViewBuilder
    private var accentColorSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                NXSegmentedControl(
                    items: [
                        (label: "System", value: false, icon: "paintpalette"),
                        (label: "Custom", value: true, icon: "eyedropper"),
                    ],
                    selection: $useCustomAccentColor,
                    showLabels: false
                )

                Group {
                    if !useCustomAccentColor {
                        systemAccentView
                            .transition(.opacity)
                    } else {
                        customAccentView
                            .transition(.opacity)
                    }
                }
                .animation(.snappy(duration: 0.25), value: useCustomAccentColor)
            }
            .padding(.vertical, 4)
        } header: {
            NXSectionHeader(title: "Accent color")
        } footer: {
            Text("Choose between your system accent color or customize it with your own selection.")
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
                .font(.caption)
        }
        .onAppear { initializeAccentColorState() }
    }

    @ViewBuilder
    private var systemAccentView: some View {
        HStack(spacing: 12) {
            AccentCircleButton(isSelected: true, color: Color.accentColor, isSystemDefault: true) {}
            VStack(alignment: .leading, spacing: 2) {
                Text("Using System Accent")
                    .font(.body)
                Text("Your macOS system accent color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var customAccentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Presets")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(PresetAccentColor.allCases) { preset in
                    AccentCircleButton(
                        isSelected: selectedPresetColor == preset,
                        color: preset.color,
                        isMulticolor: false
                    ) {
                        selectedPresetColor = preset
                        customAccentColor = preset.color
                        saveCustomColor(preset.color)
                        forceUiUpdate()
                    }
                }
                Spacer()
            }

            Divider()
                .padding(.vertical, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pick a Color")
                        .font(.body)
                    Text("Choose any color")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ColorPicker(
                    selection: Binding(
                        get: { customAccentColor },
                        set: { newColor in
                            customAccentColor = newColor
                            selectedPresetColor = nil
                            saveCustomColor(newColor)
                            forceUiUpdate()
                        }
                    ),
                    supportsOpacity: false
                ) {
                    ZStack {
                        Circle()
                            .fill(customAccentColor)
                            .frame(width: 32, height: 32)
                        if selectedPresetColor == nil {
                            Circle()
                                .strokeBorder(.primary.opacity(0.3), lineWidth: 2)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
                .labelsHidden()
            }
        }
    }

    // MARK: - Window Appearance Section

    @ViewBuilder
    private var windowAppearanceSection: some View {
        Section {
            NXStyledToggle(title: "Enable window shadow", key: .enableShadow)
            NXStyledToggle(title: "Corner radius scaling", key: .cornerRadiusScaling)
        } header: {
            NXSectionHeader(title: "Window Appearance")
        }
    }

    // MARK: - App Icon Section

    @ViewBuilder
    private var appIconSection: some View {
        Section {
            HStack {
                ForEach(icons, id: \.self) { icon in
                    Spacer()
                    VStack {
                        Image(icon)
                            .resizable()
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .circular)
                                    .strokeBorder(
                                        icon == selectedIcon ? Color.effectiveAccent : .clear,
                                        lineWidth: 2.5
                                    )
                            )
                        Text("Default")
                            .fontWeight(.medium)
                            .font(.caption)
                            .foregroundStyle(icon == selectedIcon ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(icon == selectedIcon ? Color.effectiveAccent : .clear)
                            )
                    }
                    .onTapGesture {
                        withAnimation { selectedIcon = icon }
                        NSApp.applicationIconImage = NSImage(named: icon)
                    }
                    Spacer()
                }
            }
            .disabled(true)
        } header: {
            NXSectionHeader(title: "App icon", badge: "Coming soon")
        }
    }

    // MARK: - Window Behavior Section

    @ViewBuilder
    private var windowBehaviorSection: some View {
        Section {
            NXStyledToggle(title: "Extend hover area", key: .extendHoverArea)
            NXStyledToggle(title: "Hide title bar", key: .hideTitleBar)
            NXStyledToggle(title: "Show notch on lock screen", key: .showOnLockScreen)
            NXStyledToggle(title: "Hide from screen recording", key: .hideFromScreenRecording)
        } header: {
            NXSectionHeader(title: "Window Behavior")
        }
    }

    // MARK: - Private Helpers

    private func forceUiUpdate() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("AccentColorChanged"),
                object: nil
            )
        }
    }

    private func saveCustomColor(_ color: Color) {
        let nsColor = NSColor(color)
        if let colorData = try? NSKeyedArchiver.archivedData(
            withRootObject: nsColor,
            requiringSecureCoding: false
        ) {
            Defaults[.customAccentColorData] = colorData
            forceUiUpdate()
        }
    }

    private func loadCustomColor() {
        if let colorData = Defaults[.customAccentColorData],
           let nsColor = try? NSKeyedUnarchiver.unarchivedObject(
               ofClass: NSColor.self,
               from: colorData
           )
        {
            customAccentColor = Color(nsColor: nsColor)
            selectedPresetColor = nil
            for preset in PresetAccentColor.allCases {
                if colorsAreEqual(Color(nsColor: nsColor), preset.color) {
                    selectedPresetColor = preset
                    break
                }
            }
        }
    }

    private func colorsAreEqual(_ color1: Color, _ color2: Color) -> Bool {
        let nsColor1 = NSColor(color1).usingColorSpace(.sRGB) ?? NSColor(color1)
        let nsColor2 = NSColor(color2).usingColorSpace(.sRGB) ?? NSColor(color2)
        return abs(nsColor1.redComponent - nsColor2.redComponent) < 0.01
            && abs(nsColor1.greenComponent - nsColor2.greenComponent) < 0.01
            && abs(nsColor1.blueComponent - nsColor2.blueComponent) < 0.01
    }

    private func initializeAccentColorState() {
        if !useCustomAccentColor {
            selectedPresetColor = nil
        } else {
            loadCustomColor()
        }
    }
}

// MARK: - AccentCircleButton

struct AccentCircleButton: View {

    let isSelected: Bool
    let color: Color
    var isSystemDefault: Bool = false
    var isMulticolor: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
                Circle()
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    .frame(width: 32, height: 32)
                if isSelected {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
        .help(isSystemDefault ? "Use your macOS system accent color" : "")
    }
}
