//
//  NXVisualPreviewPicker.swift
//  NotchX
//
//  A reusable design-system component that renders a horizontal row of
//  card-based preview items. Each card can show either an SF Symbol icon,
//  a custom preview view, or both (preview takes precedence). The selected
//  card is highlighted with accent-colored border and tinted fill.
//

import SwiftUI

// MARK: - Item Model

/// Describes a single selectable card in `NXVisualPreviewPicker`.
struct NXPreviewItem<Selection: Hashable>: Identifiable {
    let id = UUID()
    let label: String
    let value: Selection
    let icon: String?
    let preview: AnyView?

    /// Icon-based card (SF Symbol centered at 30pt).
    init(label: String, value: Selection, icon: String) {
        self.label = label
        self.value = value
        self.icon = icon
        self.preview = nil
    }

    /// Custom preview card (arbitrary SwiftUI content).
    init<Content: View>(
        label: String,
        value: Selection,
        @ViewBuilder preview: () -> Content
    ) {
        self.label = label
        self.value = value
        self.icon = nil
        self.preview = AnyView(preview())
    }

    /// Both icon and custom preview (preview takes precedence in rendering).
    init<Content: View>(
        label: String,
        value: Selection,
        icon: String,
        @ViewBuilder preview: () -> Content
    ) {
        self.label = label
        self.value = value
        self.icon = icon
        self.preview = AnyView(preview())
    }
}

// MARK: - NXVisualPreviewPicker

/// A horizontal row of tappable card-based preview items bound to a `Selection` value.
///
/// Each card renders either an SF Symbol icon or arbitrary SwiftUI content in a
/// fixed-height preview area, with a caption label below. Tapping a card updates
/// `selection` with a spring animation and highlights the card with accent color.
///
/// **Usage (icon-based):**
/// ```swift
/// NXVisualPreviewPicker(
///     items: [
///         NXPreviewItem(label: "All apps", value: .always, icon: "rectangle.fill"),
///         NXPreviewItem(label: "Never", value: .never, icon: "rectangle.slash"),
///     ],
///     selection: $mode
/// )
/// ```
///
/// **Usage (custom preview):**
/// ```swift
/// NXVisualPreviewPicker(
///     items: [
///         NXPreviewItem(label: "Default", value: .standard) {
///             MiniSneakPeekDefault()
///                 .scaleEffect(2.6)
///                 .frame(width: 80, height: 50)
///                 .clipped()
///         },
///     ],
///     selection: $style
/// )
/// ```
struct NXVisualPreviewPicker<Selection: Hashable & Equatable>: View {

    let items: [NXPreviewItem<Selection>]
    @Binding var selection: Selection

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            ForEach(items) { item in
                previewCard(for: item)
            }
        }
    }

    // MARK: Private helpers

    @ViewBuilder
    private func previewCard(for item: NXPreviewItem<Selection>) -> some View {
        let isSelected = selection == item.value

        Button {
            withAnimation(.spring(duration: 0.25)) {
                selection = item.value
            }
        } label: {
            VStack(spacing: 6) {
                cardContent(for: item, isSelected: isSelected)
                captionLabel(item.label, isSelected: isSelected)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    /// The card area showing either a custom preview or an SF Symbol icon.
    @ViewBuilder
    private func cardContent(
        for item: NXPreviewItem<Selection>,
        isSelected: Bool
    ) -> some View {
        Group {
            if let preview = item.preview {
                preview
            } else if let icon = item.icon {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundStyle(isSelected ? Color.effectiveAccent : Color.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(
            isSelected
                ? Color.effectiveAccent.opacity(0.1)
                : Color.gray.opacity(0.06)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? Color.effectiveAccent
                        : Color.gray.opacity(0.15),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .animation(.spring(duration: 0.25), value: isSelected)
    }

    /// Caption text rendered below the card.
    @ViewBuilder
    private func captionLabel(_ text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.system(size: 11, weight: isSelected ? .bold : .regular))
            .foregroundStyle(isSelected ? Color.effectiveAccent : Color.secondary)
            .lineLimit(1)
            .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Preview

#Preview("NXVisualPreviewPicker") {
    struct PreviewWrapper: View {

        enum DisplayStyle: String, Hashable, CaseIterable {
            case notch    = "Notch"
            case floating = "Floating"
            case minimal  = "Minimal"
        }

        enum BarStyle: String, Hashable {
            case standard = "Default"
            case inline   = "Inline"
        }

        @State private var displaySelection: DisplayStyle = .notch
        @State private var barSelection: BarStyle = .standard

        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                Text("Icon-based cards")
                    .font(.headline)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "Notch", value: DisplayStyle.notch, icon: "macbook"),
                        NXPreviewItem(label: "Floating", value: DisplayStyle.floating, icon: "rectangle.roundedtop"),
                        NXPreviewItem(label: "Minimal", value: DisplayStyle.minimal, icon: "minus.rectangle"),
                    ],
                    selection: $displaySelection
                )

                Text("Custom preview cards")
                    .font(.headline)

                NXVisualPreviewPicker(
                    items: [
                        NXPreviewItem(label: "Default", value: BarStyle.standard) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.accentColor.opacity(0.25))
                                .frame(width: 60, height: 30)
                        },
                        NXPreviewItem(label: "Inline", value: BarStyle.inline) {
                            Capsule()
                                .fill(Color.orange.opacity(0.4))
                                .frame(width: 60, height: 8)
                        },
                    ],
                    selection: $barSelection
                )
            }
            .padding(20)
            .frame(width: 420)
        }
    }

    return PreviewWrapper()
}
