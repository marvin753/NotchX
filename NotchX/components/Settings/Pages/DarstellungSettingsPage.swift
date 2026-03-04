//
//  DarstellungSettingsPage.swift
//  NotchX
//
//  Appearance settings page redesigned with the NX design system.
//  Extracted from SettingsView.swift's `Darstellung` struct (lines 1048–1279).
//

import AVFoundation
import Defaults
import SwiftUI

struct Darstellung: View {

    // MARK: - Dependencies

    @ObservedObject var coordinator = NotchXViewCoordinator.shared

    // MARK: - Defaults

    @Default(.mirrorShape) var mirrorShape
    @Default(.useMusicVisualizer) var useMusicVisualizer
    @Default(.customVisualizers) var customVisualizers
    @Default(.selectedVisualizer) var selectedVisualizer

    // MARK: - State

    let icons: [String] = ["logo2"]
    @State private var selectedIcon: String = "logo2"
    @State private var selectedListVisualizer: CustomVisualizer? = nil
    @State private var isPresented: Bool = false

    @State private var name: String = ""
    @State private var url: String = ""
    @State private var speed: Double = 1.0

    // MARK: - Body

    var body: some View {
        Form {
            notchAppearanceSection
            tileSection
            customAnimationSection
            customVisualizersSection
            additionalFeaturesSection
        }
        .accentColor(.effectiveAccent)
        .navigationTitle("Darstellung")
    }

    // MARK: - Notch Appearance

    @ViewBuilder
    private var notchAppearanceSection: some View {
        Section {
            NXStyledToggleBinding(
                title: "Always show tabs",
                isOn: $coordinator.alwaysShowTabs
            )

            NXStyledToggle(
                title: "Show settings button in notch",
                key: .settingsIconInNotch
            )
        } header: {
            NXSectionHeader(title: "Notch appearance")
        }
    }

    // MARK: - Tile

    @ViewBuilder
    private var tileSection: some View {
        Section {
            NXStyledToggle(title: "Show tile labels", key: .tileShowLabels)
        } header: {
            NXSectionHeader(title: "Tile")
        }
    }

    // MARK: - Custom Music Live Activity Animation

    @ViewBuilder
    private var customAnimationSection: some View {
        Section {
            NXStyledToggle(
                title: "Use custom animation",
                key: .useMusicVisualizer,
                isDisabled: true
            )

            if !useMusicVisualizer {
                if customVisualizers.count > 0 {
                    Picker("Selected animation", selection: $selectedVisualizer) {
                        ForEach(customVisualizers, id: \.self) { visualizer in
                            Text(visualizer.name).tag(visualizer)
                        }
                    }
                } else {
                    HStack {
                        Text("Selected animation")
                        Spacer()
                        Text("No custom animation available")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            NXSectionHeader(
                title: "Custom music live activity animation",
                badge: "Coming soon"
            )
        }
    }

    // MARK: - Custom Visualizers List

    @ViewBuilder
    private var customVisualizersSection: some View {
        Section {
            List {
                ForEach(customVisualizers, id: \.self) { visualizer in
                    HStack {
                        LottieView(url: visualizer.url, speed: visualizer.speed, loopMode: .loop)
                            .frame(width: 30, height: 30, alignment: .center)
                        Text(visualizer.name)
                        Spacer(minLength: 0)
                        if selectedVisualizer == visualizer {
                            Text("selected")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .padding(.trailing, 8)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.vertical, 2)
                    .background(
                        selectedListVisualizer != nil
                            ? selectedListVisualizer == visualizer
                                ? Color.effectiveAccent : Color.clear
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 5)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedListVisualizer == visualizer {
                            selectedListVisualizer = nil
                            return
                        }
                        selectedListVisualizer = visualizer
                    }
                }
            }
            .safeAreaPadding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
            .frame(minHeight: 120)
            .actionBar {
                HStack(spacing: 5) {
                    Button {
                        name = ""; url = ""; speed = 1.0
                        isPresented.toggle()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.secondary)
                            .contentShape(Rectangle())
                    }
                    Divider()
                    Button {
                        if let visualizer = selectedListVisualizer {
                            selectedListVisualizer = nil
                            customVisualizers.remove(
                                at: customVisualizers.firstIndex(of: visualizer)!
                            )
                            if visualizer == selectedVisualizer, customVisualizers.count > 0 {
                                selectedVisualizer = customVisualizers[0]
                            }
                        }
                    } label: {
                        Image(systemName: "minus")
                            .foregroundStyle(.secondary)
                            .contentShape(Rectangle())
                    }
                }
            }
            .controlSize(.small)
            .buttonStyle(PlainButtonStyle())
            .overlay {
                if customVisualizers.isEmpty {
                    Text("No custom visualizer")
                        .foregroundStyle(Color(.secondaryLabelColor))
                        .padding(.bottom, 22)
                }
            }
            .sheet(isPresented: $isPresented) {
                addVisualizerSheet
            }
        } header: {
            NXSectionHeader(
                title: customVisualizers.isEmpty
                    ? "Custom vizualizers (Lottie)"
                    : "Custom vizualizers (Lottie) – \(customVisualizers.count)"
            )
        }
    }

    // MARK: - Add Visualizer Sheet

    @ViewBuilder
    private var addVisualizerSheet: some View {
        VStack(alignment: .leading) {
            Text("Add new visualizer")
                .font(.largeTitle.bold())
                .padding(.vertical)

            TextField("Name", text: $name)
            TextField("Lottie JSON URL", text: $url)

            HStack {
                Text("Speed")
                Spacer(minLength: 80)
                Text("\(speed, specifier: "%.1f")s")
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
                Slider(value: $speed, in: 0...2, step: 0.1)
            }
            .padding(.vertical)

            HStack {
                Button {
                    isPresented.toggle()
                } label: {
                    Text("Cancel").frame(maxWidth: .infinity, alignment: .center)
                }

                Button {
                    let visualizer = CustomVisualizer(
                        UUID: UUID(),
                        name: name,
                        url: URL(string: url)!,
                        speed: speed
                    )
                    if !customVisualizers.contains(visualizer) {
                        customVisualizers.append(visualizer)
                    }
                    isPresented.toggle()
                } label: {
                    Text("Add").frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(BorderedProminentButtonStyle())
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .controlSize(.extraLarge)
        .padding()
    }

    // MARK: - Additional Features

    @ViewBuilder
    private var additionalFeaturesSection: some View {
        Section {
            NXStyledToggle(
                title: "Enable mirror",
                key: .showMirror,
                isDisabled: !checkVideoInput()
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Mirror shape")
                    .font(.body)

                NXSegmentedControl(
                    items: [
                        (label: "Circle", value: MirrorShapeEnum.circle, icon: "circle"),
                        (label: "Square", value: MirrorShapeEnum.rectangle, icon: "square"),
                    ],
                    selection: $mirrorShape,
                    showLabels: false
                )
            }

            NXStyledToggle(
                title: "Show cool face animation while inactive",
                key: .showNotHumanFace
            )
        } header: {
            NXSectionHeader(title: "Additional features")
        }
    }

    // MARK: - Helpers

    func checkVideoInput() -> Bool {
        AVCaptureDevice.default(for: .video) != nil
    }
}
