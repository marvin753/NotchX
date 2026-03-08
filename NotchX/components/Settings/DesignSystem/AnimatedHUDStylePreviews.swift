//
//  AnimatedHUDStylePreviews.swift
//  NotchX
//
//  Animated miniature Notch previews for the HUD style picker in Settings.
//  Extracted for independent iteration on animation design.
//

import SwiftUI
import Defaults

// MARK: - Animated HUD Previews

/// A miniature display shell: rounded rect background with a `NotchShape` cutout at top-center.
struct MiniDisplayShell<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack(alignment: .top) {
            // Display body
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(white: 0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )

            // Inner content
            content
        }
        .frame(width: 160, height: 67)
    }
}

/// An animated capsule progress bar with a track and fill.
struct MiniProgressBar: View {
    let progress: CGFloat
    let trackWidth: CGFloat
    let barHeight: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: trackWidth, height: barHeight)
            Capsule()
                .fill(Color.white.opacity(0.85))
                .frame(width: max(barHeight, trackWidth * progress), height: barHeight)
        }
    }
}

/// Default HUD preview: the black NotchShape expands downward to reveal icon + bar below the notch.
/// Simulates the real HUD lifecycle: idle → expand → adjust → adjust → collapse → repeat.
struct AnimatedHUDDefaultPreview: View {
    let isDisplayPage: Bool
    @Default(.showClosedNotchHUDPercentage) var showPercentage

    @State private var expanded: Bool = false
    @State private var progressValue: CGFloat = 0.5

    private let closedWidth: CGFloat = 50
    private let closedHeight: CGFloat = 12
    private let expandedWidth: CGFloat = 68
    private let expandedHeight: CGFloat = 30
    private let barWidth: CGFloat = 26
    private let barHt: CGFloat = 2.5

    private var iconName: String {
        isDisplayPage ? "sun.max.fill" : "speaker.wave.2.fill"
    }

    private var currentWidth: CGFloat {
        expanded ? expandedWidth : closedWidth
    }

    private var currentHeight: CGFloat {
        expanded ? expandedHeight : closedHeight
    }

    var body: some View {
        MiniDisplayShell {
            VStack(spacing: 0) {
                // The entire notch + HUD is ONE black shape
                VStack(spacing: 0) {
                    // Top spacer: the "physical" notch area
                    Spacer()
                        .frame(height: closedHeight)

                    // Bottom: HUD content row (visible when expanded)
                    if expanded {
                        HStack(spacing: 2) {
                            Image(systemName: iconName)
                                .font(.system(size: 5, weight: .medium))
                                .foregroundStyle(.white)

                            MiniProgressBar(progress: progressValue, trackWidth: barWidth, barHeight: barHt)

                            if showPercentage {
                                Text("\(Int(progressValue * 100))%")
                                    .font(.system(size: 5, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .monospacedDigit()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: 14, alignment: .trailing)
                            }
                        }
                        .padding(.top, 1)
                        .padding(.bottom, 2)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .top)))
                    }
                }
                .frame(width: currentWidth, height: currentHeight)
                .background(.black)
                .clipShape(NotchShape(
                    topCornerRadius: expanded ? 4 : 3,
                    bottomCornerRadius: expanded ? 10 : 6
                ))
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: expanded)
            }
        }
        .task { await runAnimationLoop() }
    }

    private func runAnimationLoop() async {
        while !Task.isCancelled {
            // Phase 1: Idle — notch at closed size
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }

            // Phase 2: Expand notch + show HUD
            progressValue = CGFloat.random(in: 0.5...0.85)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                expanded = true
            }
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            // Phase 3: First adjustment
            withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                progressValue = CGFloat.random(in: 0.2...0.5)
            }
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            // Phase 4: Second adjustment
            withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                progressValue = CGFloat.random(in: 0.3...0.7)
            }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }

            // Phase 5: Collapse notch
            withAnimation(.spring(response: 0.45, dampingFraction: 1.0)) {
                expanded = false
            }
            try? await Task.sleep(for: .seconds(0.5))
        }
    }
}

/// Inline HUD preview: the black NotchShape expands sideways to reveal label left + bar right.
/// Simulates the real HUD lifecycle: idle → expand → adjust → adjust → collapse → repeat.
struct AnimatedHUDInlinePreview: View {
    let isDisplayPage: Bool
    @Default(.showClosedNotchHUDPercentage) var showPercentage

    @State private var expanded: Bool = false
    @State private var progressValue: CGFloat = 0.5

    private let closedWidth: CGFloat = 50
    private let expandedWidth: CGFloat = 140
    private let notchHeight: CGFloat = 12
    private let barWidth: CGFloat = 26
    private let barHt: CGFloat = 2.5

    private var iconName: String {
        isDisplayPage ? "sun.max.fill" : "speaker.wave.2.fill"
    }

    private var label: String {
        isDisplayPage ? "Brightness" : "Volume"
    }

    private var currentWidth: CGFloat {
        expanded ? expandedWidth : closedWidth
    }

    var body: some View {
        MiniDisplayShell {
            // The entire notch + side content is ONE black shape
            HStack(spacing: 0) {
                if expanded {
                    // Left wing: icon + label (balanced to fit within notch)
                    HStack(spacing: 2) {
                        Image(systemName: iconName)
                            .font(.system(size: 5.5, weight: .medium))
                            .foregroundStyle(.white)
                        Text(label)
                            .font(.system(size: 5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 3)
                    .transition(.opacity)
                }

                // Center: notch body spacer (always present)
                Rectangle()
                    .fill(.clear)
                    .frame(width: closedWidth - 10)

                if expanded {
                    // Right wing: bar + optional % (balanced to fit within notch)
                    HStack(spacing: 2) {
                        MiniProgressBar(progress: progressValue, trackWidth: barWidth, barHeight: barHt)

                        if showPercentage {
                            Text("\(Int(progressValue * 100))%")
                                .font(.system(size: 5, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .frame(width: 14, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 3)
                    .transition(.opacity)
                }
            }
            .frame(width: currentWidth, height: notchHeight)
            .background(.black)
            .clipShape(NotchShape(
                topCornerRadius: expanded ? 3 : 3,
                bottomCornerRadius: expanded ? 8 : 6
            ))
            .animation(.spring(response: 0.42, dampingFraction: 0.8), value: expanded)
        }
        .task { await runAnimationLoop() }
    }

    private func runAnimationLoop() async {
        while !Task.isCancelled {
            // Phase 1: Idle — notch at closed (narrow) width
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }

            // Phase 2: Expand notch sideways + show HUD
            progressValue = CGFloat.random(in: 0.5...0.85)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                expanded = true
            }
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            // Phase 3: First adjustment
            withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                progressValue = CGFloat.random(in: 0.2...0.5)
            }
            try? await Task.sleep(for: .seconds(0.8))
            guard !Task.isCancelled else { return }

            // Phase 4: Second adjustment
            withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                progressValue = CGFloat.random(in: 0.3...0.7)
            }
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }

            // Phase 5: Collapse notch
            withAnimation(.spring(response: 0.45, dampingFraction: 1.0)) {
                expanded = false
            }
            try? await Task.sleep(for: .seconds(0.5))
        }
    }
}

// MARK: - Previews

#Preview("HUD Style – Closed Notch (Display & Sound)") {
    struct PreviewWrapper: View {
        @State private var displaySelection = false  // false = Default, true = Inline
        @State private var soundSelection = false

        var body: some View {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HUD style")
                            .font(.body)

                        NXVisualPreviewPicker(
                            items: [
                                NXPreviewItem(label: "Default", value: false) {
                                    AnimatedHUDDefaultPreview(isDisplayPage: true)
                                },
                                NXPreviewItem(label: "Inline", value: true) {
                                    AnimatedHUDInlinePreview(isDisplayPage: true)
                                },
                            ],
                            selection: $displaySelection,
                            cardHeight: 95
                        )
                    }
                } header: {
                    Text("Display")
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("HUD style")
                            .font(.body)

                        NXVisualPreviewPicker(
                            items: [
                                NXPreviewItem(label: "Default", value: false) {
                                    AnimatedHUDDefaultPreview(isDisplayPage: false)
                                },
                                NXPreviewItem(label: "Inline", value: true) {
                                    AnimatedHUDInlinePreview(isDisplayPage: false)
                                },
                            ],
                            selection: $soundSelection,
                            cardHeight: 95
                        )
                    }
                } header: {
                    Text("Sound")
                }
            }
            .padding(20)
            .frame(width: 420)
        }
    }
    return PreviewWrapper()
}
