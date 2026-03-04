//
//  NXIconGridPicker.swift
//  NotchX
//
//  A reusable design-system component that renders a grid of icon cards,
//  each displaying an SF Symbol (or a color swatch) above a caption label.
//  The selected card is highlighted with the app's effective accent color
//  and springs to a slightly larger scale on selection.
//

import SwiftUI

// MARK: - Item Model

/// Describes a single selectable card in `NXIconGridPicker`.
///
/// Two convenience initialisers cover the two supported variants:
/// - **Symbol variant** — pass `icon:` with an SF Symbol name.
/// - **Color variant** — pass `color:` with a `Color` value; renders a filled circle instead of a symbol.
struct NXIconGridItem<Selection: Hashable> {
    let label: String
    let value: Selection
    /// SF Symbol name used in the symbol variant. `nil` when the color variant is active.
    let icon: String?
    /// Swatch color used in the color variant. `nil` when the symbol variant is active.
    let color: Color?

    // MARK: Convenience initialisers

    /// Creates a symbol-variant item backed by an SF Symbol.
    init(label: String, value: Selection, icon: String) {
        self.label = label
        self.value = value
        self.icon = icon
        self.color = nil
    }

    /// Creates a color-variant item that renders a filled circle in the given color.
    init(label: String, value: Selection, color: Color) {
        self.label = label
        self.value = value
        self.icon = nil
        self.color = color
    }
}

// MARK: - NXIconGridPicker

/// A horizontal grid of tappable icon cards bound to a `Selection` value.
///
/// For four or more items the layout automatically switches from a plain
/// `HStack` to a `LazyVGrid` with an adaptive minimum column width so the
/// cards wrap onto multiple rows rather than becoming too narrow to read.
///
/// **Symbol variant usage:**
/// ```swift
/// @State private var alignment: TextAlignment = .leading
///
/// NXIconGridPicker(
///     items: [
///         NXIconGridItem(label: "Left",   value: TextAlignment.leading,  icon: "text.alignleft"),
///         NXIconGridItem(label: "Center", value: TextAlignment.center,   icon: "text.aligncenter"),
///         NXIconGridItem(label: "Right",  value: TextAlignment.trailing, icon: "text.alignright"),
///     ],
///     selection: $alignment
/// )
/// ```
///
/// **Color variant usage:**
/// ```swift
/// @State private var fontColor: TeleprompterFontColor = .white
///
/// NXIconGridPicker(
///     items: [
///         NXIconGridItem(label: "White",  value: TeleprompterFontColor.white,  color: .white),
///         NXIconGridItem(label: "Yellow", value: TeleprompterFontColor.yellow, color: .yellow),
///     ],
///     selection: $fontColor
/// )
/// ```
struct NXIconGridPicker<Selection: Hashable & Equatable>: View {

    let items: [NXIconGridItem<Selection>]
    @Binding var selection: Selection

    // Cards switch to a wrapping grid when there are four or more items.
    private var usesGrid: Bool { items.count >= 4 }

    // MARK: Body

    var body: some View {
        Group {
            if usesGrid {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 60, maximum: 100))],
                    alignment: .leading,
                    spacing: 8
                ) {
                    cardRow
                }
            } else {
                HStack(spacing: 8) {
                    cardRow
                }
            }
        }
    }

    // MARK: Card row

    @ViewBuilder
    private var cardRow: some View {
        ForEach(items, id: \.value) { item in
            iconCard(for: item)
        }
    }

    // MARK: Individual card

    @ViewBuilder
    private func iconCard(for item: NXIconGridItem<Selection>) -> some View {
        let isSelected = selection == item.value

        Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.25)) {
                selection = item.value
            }
        } label: {
            VStack(spacing: 5) {
                iconSquare(for: item, isSelected: isSelected)
                captionLabel(item.label, isSelected: isSelected)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(duration: 0.3, bounce: 0.25), value: isSelected)
    }

    // MARK: Icon square (44 x 44, cornerRadius 10)

    @ViewBuilder
    private func iconSquare(
        for item: NXIconGridItem<Selection>,
        isSelected: Bool
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    isSelected
                        ? Color.effectiveAccent
                        : Color(nsColor: .controlBackgroundColor)
                )
                .animation(.spring(duration: 0.3, bounce: 0.25), value: isSelected)

            iconContent(for: item, isSelected: isSelected)
        }
        .frame(width: 44, height: 44)
        // Subtle border on unselected cards so they read against varied backgrounds
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? Color.clear
                        : Color(nsColor: .separatorColor).opacity(0.6),
                    lineWidth: 1
                )
        }
    }

    // MARK: Icon content — symbol or color swatch

    @ViewBuilder
    private func iconContent(
        for item: NXIconGridItem<Selection>,
        isSelected: Bool
    ) -> some View {
        if let symbolName = item.icon {
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .animation(.spring(duration: 0.3, bounce: 0.25), value: isSelected)
        } else if let swatch = item.color {
            Circle()
                .fill(swatch)
                .frame(width: 24, height: 24)
                .overlay {
                    // Ring uses accent on selection, separator otherwise
                    Circle()
                        .strokeBorder(
                            isSelected ? Color.white.opacity(0.5) : Color(nsColor: .separatorColor),
                            lineWidth: 1.5
                        )
                }
        }
    }

    // MARK: Caption label

    @ViewBuilder
    private func captionLabel(_ text: String, isSelected: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(isSelected ? Color.effectiveAccent : Color.secondary)
            .lineLimit(1)
            .animation(.spring(duration: 0.3, bounce: 0.25), value: isSelected)
    }
}

// MARK: - Preview

#Preview("Symbol variant — 3 items (HStack)") {
    struct PreviewWrapper: View {
        enum TextAlign: String, Hashable, CaseIterable {
            case leading  = "Left"
            case center   = "Center"
            case trailing = "Right"
        }

        @State private var align: TextAlign = .leading

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Alignment")
                    .font(.headline)

                NXIconGridPicker(
                    items: [
                        NXIconGridItem(label: "Left",   value: TextAlign.leading,  icon: "text.alignleft"),
                        NXIconGridItem(label: "Center", value: TextAlign.center,   icon: "text.aligncenter"),
                        NXIconGridItem(label: "Right",  value: TextAlign.trailing, icon: "text.alignright"),
                    ],
                    selection: $align
                )
            }
            .padding(20)
            .frame(width: 320)
        }
    }

    return PreviewWrapper()
}

#Preview("Symbol variant — 6 items (LazyVGrid)") {
    struct PreviewWrapper: View {
        @State private var selected = "circle"

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Shape")
                    .font(.headline)

                NXIconGridPicker(
                    items: [
                        NXIconGridItem(label: "Circle",   value: "circle",    icon: "circle"),
                        NXIconGridItem(label: "Square",   value: "square",    icon: "square"),
                        NXIconGridItem(label: "Triangle", value: "triangle",  icon: "triangle"),
                        NXIconGridItem(label: "Star",     value: "star",      icon: "star"),
                        NXIconGridItem(label: "Heart",    value: "heart",     icon: "heart"),
                        NXIconGridItem(label: "Diamond",  value: "diamond",   icon: "diamond"),
                    ],
                    selection: $selected
                )
            }
            .padding(20)
            .frame(width: 320)
        }
    }

    return PreviewWrapper()
}

#Preview("Color variant — font color picker") {
    struct PreviewWrapper: View {
        enum FontColor: String, Hashable, CaseIterable {
            case white  = "White"
            case yellow = "Yellow"
            case green  = "Green"
            case cyan   = "Cyan"
        }

        var colorMap: [FontColor: Color] = [
            .white:  .white,
            .yellow: .yellow,
            .green:  .green,
            .cyan:   .cyan,
        ]

        @State private var fontColor: FontColor = .white

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Highlight Color")
                    .font(.headline)

                NXIconGridPicker(
                    items: FontColor.allCases.map { c in
                        NXIconGridItem(label: c.rawValue, value: c, color: colorMap[c]!)
                    },
                    selection: $fontColor
                )
            }
            .padding(20)
            .frame(width: 320)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    return PreviewWrapper()
}
