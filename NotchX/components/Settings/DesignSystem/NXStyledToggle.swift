//
//  NXStyledToggle.swift
//  NotchX
//
//  A reusable design-system toggle row that pairs a title and an optional
//  subtitle on the leading side with a tinted switch on the trailing side.
//  A subtle spring-driven scale pulse plays each time the switch is flipped.
//  Two variants are provided: one backed by a `Defaults.Key<Bool>` and one
//  backed by a plain `Binding<Bool>` for non-Defaults state (e.g. LaunchAtLogin).
//

import SwiftUI
import Defaults

// MARK: - NXStyledToggle (Defaults.Key variant)

/// A labelled toggle row wired to a `Defaults.Key<Bool>`.
///
/// **Usage:**
/// ```swift
/// NXStyledToggle(
///     title: "Enable feature",
///     subtitle: "Short description of what this controls.",
///     key: .myFeatureEnabled
/// )
///
/// // Disabled state — rendered at 50 % opacity and non-interactive:
/// NXStyledToggle(
///     title: "Requires permission",
///     key: .myFeatureEnabled,
///     isDisabled: true
/// )
/// ```
struct NXStyledToggle: View {

    let title: String
    let subtitle: String?
    let key: Defaults.Key<Bool>
    var isDisabled: Bool

    // Drives the scale pulse animation.
    @State private var scale: CGFloat = 1.0

    // MARK: Init

    init(
        title: String,
        subtitle: String? = nil,
        key: Defaults.Key<Bool>,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self.key = key
        self.isDisabled = isDisabled
    }

    // MARK: Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            labelStack
            Spacer(minLength: 12)
            Defaults.Toggle("", key: key)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color.effectiveAccent)
                .scaleEffect(scale)
                .onChange(of: Defaults[key]) { _, _ in
                    pulse()
                }
        }
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
    }

    // MARK: Private helpers

    @ViewBuilder
    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func pulse() {
        withAnimation(.spring(duration: 0.1)) {
            scale = 0.97
        }
        withAnimation(.spring(duration: 0.2).delay(0.1)) {
            scale = 1.0
        }
    }
}

// MARK: - NXStyledToggleBinding (Binding<Bool> variant)

/// A labelled toggle row wired to a plain `Binding<Bool>`.
///
/// Use this variant for state that lives outside `Defaults`, such as
/// `LaunchAtLogin.isEnabled` or a local `@State` / `@AppStorage` property.
///
/// **Usage:**
/// ```swift
/// NXStyledToggleBinding(
///     title: "Launch at Login",
///     subtitle: "Start NotchX automatically when you log in.",
///     isOn: Binding(
///         get: { LaunchAtLogin.isEnabled },
///         set: { LaunchAtLogin.isEnabled = $0 }
///     )
/// )
/// ```
struct NXStyledToggleBinding: View {

    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    var isDisabled: Bool

    // Drives the scale pulse animation.
    @State private var scale: CGFloat = 1.0

    // MARK: Init

    init(
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
        self.isDisabled = isDisabled
    }

    // MARK: Body

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            labelStack
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(Color.effectiveAccent)
                .scaleEffect(scale)
                .onChange(of: isOn) { _, _ in
                    pulse()
                }
        }
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.5 : 1.0)
        .disabled(isDisabled)
    }

    // MARK: Private helpers

    @ViewBuilder
    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.body)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func pulse() {
        withAnimation(.spring(duration: 0.1)) {
            scale = 0.97
        }
        withAnimation(.spring(duration: 0.2).delay(0.1)) {
            scale = 1.0
        }
    }
}

// MARK: - Previews

#Preview("Defaults variant — with subtitle") {
    VStack(spacing: 0) {
        NXStyledToggle(
            title: "Enable Teleprompter",
            subtitle: "Display a scrolling script inside the notch during presentations.",
            key: .teleprompterEnabled
        )
        .padding()

        Divider()

        NXStyledToggle(
            title: "No subtitle"  ,
            key: .teleprompterEnabled
        )
        .padding()

        Divider()

        NXStyledToggle(
            title: "Disabled row",
            subtitle: "This option is unavailable until accessibility is granted.",
            key: .teleprompterEnabled,
            isDisabled: true
        )
        .padding()
    }
    .frame(width: 380)
}

#Preview("Binding variant") {
    struct PreviewWrapper: View {
        @State private var isOn = false

        var body: some View {
            VStack(spacing: 0) {
                NXStyledToggleBinding(
                    title: "Launch at Login",
                    subtitle: "Start NotchX automatically when you log in.",
                    isOn: $isOn
                )
                .padding()

                Divider()

                NXStyledToggleBinding(
                    title: "Launch at Login",
                    subtitle: "Requires full-disk access.",
                    isOn: $isOn,
                    isDisabled: true
                )
                .padding()
            }
            .frame(width: 380)
        }
    }

    return PreviewWrapper()
}
