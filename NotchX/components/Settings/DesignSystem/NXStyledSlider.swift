//
//  NXStyledSlider.swift
//  NotchX
//
//  A reusable design-system slider that pairs a title and live value badge
//  on a top row with a tinted `Slider` below. The value badge animates
//  smoothly between numbers using `.numericText()` content transitions.
//  Optional min/max labels can be shown at either end of the track.
//

import SwiftUI

// MARK: - NXStyledSlider

/// A labelled slider row with an animated value badge.
///
/// The badge format adapts to `step`: values whose step is >= 1 are shown
/// without decimals ("%.0f"), while finer steps use one decimal place ("%.1f").
/// An optional `unit` string (e.g. "px", "%", "s") is appended after the number.
///
/// **Usage (basic):**
/// ```swift
/// @State private var speed: Double = 1.0
///
/// NXStyledSlider(
///     value: $speed,
///     title: "Scroll Speed",
///     range: 0.5...4.0,
///     step: 0.5,
///     unit: "×"
/// )
/// ```
///
/// **Usage (with end labels):**
/// ```swift
/// NXStyledSlider(
///     value: $speed,
///     title: "Scroll Speed",
///     range: 0.5...4.0,
///     step: 0.5,
///     minLabel: "Slow",
///     maxLabel: "Fast"
/// )
/// ```
struct NXStyledSlider: View {

    @Binding var value: Double
    let title: String
    let range: ClosedRange<Double>
    let step: Double
    var unit: String = ""
    var minLabel: String? = nil
    var maxLabel: String? = nil

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            sliderRow
        }
    }

    // MARK: Private subviews

    /// Title on the left, animated value badge on the right.
    @ViewBuilder
    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.body)

            Spacer(minLength: 8)

            Text(formattedValue)
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(Color.secondary)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: value)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(nsColor: .secondarySystemFill))
                )
        }
    }

    /// The slider itself with optional min/max end labels.
    @ViewBuilder
    private var sliderRow: some View {
        if minLabel != nil || maxLabel != nil {
            HStack(spacing: 6) {
                if let minLabel {
                    Text(minLabel)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                track

                if let maxLabel {
                    Text(maxLabel)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
        } else {
            track
        }
    }

    /// The raw `Slider` control.
    private var track: some View {
        Slider(value: $value, in: range, step: step)
            .tint(Color.effectiveAccent)
    }

    // MARK: Formatting

    private var formattedValue: String {
        let format = step >= 1 ? "%.0f" : "%.1f"
        let number = String(format: format, value)
        return unit.isEmpty ? number : "\(number)\(unit)"
    }
}

// MARK: - Preview

#Preview("Basic — integer step") {
    struct PreviewWrapper: View {
        @State private var size: Double = 32

        var body: some View {
            NXStyledSlider(
                value: $size,
                title: "Font Size",
                range: 12...72,
                step: 1,
                unit: " pt"
            )
            .padding()
            .frame(width: 360)
        }
    }
    return PreviewWrapper()
}

#Preview("Decimal step — with end labels") {
    struct PreviewWrapper: View {
        @State private var speed: Double = 1.0

        var body: some View {
            NXStyledSlider(
                value: $speed,
                title: "Scroll Speed",
                range: 0.5...4.0,
                step: 0.5,
                unit: "×",
                minLabel: "Slow",
                maxLabel: "Fast"
            )
            .padding()
            .frame(width: 360)
        }
    }
    return PreviewWrapper()
}

#Preview("Percentage — no unit label") {
    struct PreviewWrapper: View {
        @State private var opacity: Double = 80

        var body: some View {
            NXStyledSlider(
                value: $opacity,
                title: "Background Opacity",
                range: 0...100,
                step: 5,
                unit: "%"
            )
            .padding()
            .frame(width: 360)
        }
    }
    return PreviewWrapper()
}
