//
//  NXStepperField.swift
//  NotchX
//
//  A reusable design-system stepper row that pairs a title on the leading
//  side with a compact value+unit display and custom circle +/− buttons on
//  the trailing side. The value animates smoothly with `.numericText()`.
//  The decrement button dims at the range minimum; the increment button
//  dims at the range maximum.
//

import SwiftUI

// MARK: - NXStepperField

/// A labelled stepper row with animated value display and accent-tinted buttons.
///
/// The value format adapts to `step`: fractional steps (< 1) use one decimal
/// place ("%.1f"), while integer steps use no decimals ("%.0f"). The `unit`
/// string is shown after a space (e.g. "3 s", "5 m", "0.5 ×").
///
/// **Usage:**
/// ```swift
/// @State private var duration: Double = 3
///
/// NXStepperField(
///     title: "Auto-close delay",
///     value: $duration,
///     range: 1...30,
///     step: 1,
///     unit: "s"
/// )
/// ```
struct NXStepperField: View {

    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let unit: String

    // MARK: Body

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.body)

            Spacer(minLength: 12)

            valueLabel

            HStack(spacing: 4) {
                stepButton(
                    systemName: "minus.circle.fill",
                    isDisabled: value <= range.lowerBound
                ) {
                    adjustValue(by: -step)
                }

                stepButton(
                    systemName: "plus.circle.fill",
                    isDisabled: value >= range.upperBound
                ) {
                    adjustValue(by: step)
                }
            }
        }
    }

    // MARK: Private subviews

    /// Animated numeric value with unit suffix.
    private var valueLabel: some View {
        Text(formattedValue)
            .font(.body.monospacedDigit())
            .foregroundStyle(Color.effectiveAccent)
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.3), value: value)
    }

    /// A single circle stepper button.
    @ViewBuilder
    private func stepButton(
        systemName: String,
        isDisabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.title3)
                .foregroundStyle(Color.effectiveAccent)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.3 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDisabled)
    }

    // MARK: Private helpers

    private func adjustValue(by delta: Double) {
        let next = (value + delta).rounded(toStep: step)
        withAnimation(.spring(duration: 0.25)) {
            value = min(range.upperBound, max(range.lowerBound, next))
        }
    }

    private var formattedValue: String {
        let format = step < 1 ? "%.1f" : "%.0f"
        return String(format: format, value) + " \(unit)"
    }
}

// MARK: - Double rounding helper

private extension Double {
    /// Rounds `self` to the nearest multiple of `step`, avoiding floating-point
    /// drift that accumulates when adding small fractional values repeatedly.
    func rounded(toStep step: Double) -> Double {
        guard step > 0 else { return self }
        return (self / step).rounded() * step
    }
}

// MARK: - Preview

#Preview("Integer step") {
    struct PreviewWrapper: View {
        @State private var delay: Double = 3

        var body: some View {
            NXStepperField(
                title: "Auto-close delay",
                value: $delay,
                range: 1...30,
                step: 1,
                unit: "s"
            )
            .padding()
            .frame(width: 340)
        }
    }
    return PreviewWrapper()
}

#Preview("Fractional step") {
    struct PreviewWrapper: View {
        @State private var multiplier: Double = 1.0

        var body: some View {
            NXStepperField(
                title: "Speed multiplier",
                value: $multiplier,
                range: 0.5...4.0,
                step: 0.5,
                unit: "×"
            )
            .padding()
            .frame(width: 340)
        }
    }
    return PreviewWrapper()
}

#Preview("At bounds — buttons disabled") {
    struct PreviewWrapper: View {
        @State private var minutes: Double = 1

        var body: some View {
            VStack(spacing: 0) {
                NXStepperField(
                    title: "At minimum",
                    value: $minutes,
                    range: 1...60,
                    step: 1,
                    unit: "m"
                )
                .padding()

                Divider()

                NXStepperField(
                    title: "At maximum",
                    value: .constant(60),
                    range: 1...60,
                    step: 1,
                    unit: "m"
                )
                .padding()
            }
            .frame(width: 340)
        }
    }
    return PreviewWrapper()
}
