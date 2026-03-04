//
//  NXSegmentedControl.swift
//  NotchX
//
//  A reusable segmented control with a sliding accent-colored pill indicator,
//  built with matchedGeometryEffect for smooth spring-driven transitions.
//  Supports text-only, icon+text, icon-only, and image+text item variants.
//

import SwiftUI

// MARK: - Symbol Animation

/// Animation style applied to an SF Symbol in a segment.
enum NXSymbolAnimation {
    case bounce    // one-shot bounce on activation
    case pulse     // pulses while active
    case variable  // variableColor while active
}

// MARK: - Segment Content

/// Describes the leading graphic content of a segment.
enum NXSegmentContent {
    case icon(String)                              // static SF Symbol
    case animatedIcon(String, NXSymbolAnimation)   // SF Symbol + animation
    case custom(AnyView)                           // arbitrary SwiftUI view
}

// MARK: - Item Model

/// Describes a single segment in `NXSegmentedControl`.
struct NXSegmentItem<Value: Hashable> {
    let label: String
    let value: Value
    /// Optional SF Symbol name shown to the left of the label.
    let icon: String?
    /// Optional asset-catalog image name shown to the left of the label.
    /// `icon` takes precedence when both are supplied.
    let image: String?
    /// Rich content descriptor — checked before `icon`/`image`.
    let content: NXSegmentContent?

    // MARK: Convenience initialisers

    init(label: String, value: Value) {
        self.label = label
        self.value = value
        self.icon = nil
        self.image = nil
        self.content = nil
    }

    init(label: String, value: Value, icon: String) {
        self.label = label
        self.value = value
        self.icon = icon
        self.image = nil
        self.content = nil
    }

    init(label: String, value: Value, image: String) {
        self.label = label
        self.value = value
        self.icon = nil
        self.image = image
        self.content = nil
    }

    init(label: String, value: Value, icon: String?, image: String?) {
        self.label = label
        self.value = value
        self.icon = icon
        self.image = image
        self.content = nil
    }

    init(label: String, value: Value, content: NXSegmentContent) {
        self.label = label
        self.value = value
        self.icon = nil
        self.image = nil
        self.content = content
    }
}

// MARK: - NXSegmentedControl

/// A horizontal segmented control with a sliding accent-pill highlight.
///
/// Usage (text-only):
/// ```swift
/// NXSegmentedControl(
///     items: [("Default", 0), ("Inline", 1)].map { NXSegmentItem(label: $0.0, value: $0.1) },
///     selection: $selectedIndex
/// )
/// ```
///
/// Usage (icon-only):
/// ```swift
/// NXSegmentedControl(
///     items: [
///         NXSegmentItem(label: "Grid",  value: .grid,  icon: "square.grid.2x2"),
///         NXSegmentItem(label: "List",  value: .list,  icon: "list.bullet"),
///     ],
///     selection: $layoutMode,
///     showLabels: false
/// )
/// ```
struct NXSegmentedControl<Selection: Hashable & Equatable>: View {

    let items: [NXSegmentItem<Selection>]
    @Binding var selection: Selection
    let showLabels: Bool
    @Namespace private var pillNamespace

    init(items: [NXSegmentItem<Selection>], selection: Binding<Selection>, showLabels: Bool = true) {
        self.items = items
        self._selection = selection
        self.showLabels = showLabels
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.value) { item in
                segmentButton(for: item)
            }
        }
        .padding(3)
        .background(
            Capsule(style: .continuous)
                .fill(Color(nsColor: .secondarySystemFill))
        )
    }

    // MARK: Private helpers

    @ViewBuilder
    private func segmentButton(for item: NXSegmentItem<Selection>) -> some View {
        let isActive = selection == item.value

        Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                selection = item.value
            }
        } label: {
            segmentLabel(for: item, isActive: isActive)
        }
        .buttonStyle(.plain)
        .background(pillBackground(isActive: isActive))
        .help(showLabels ? "" : item.label)
    }

    @ViewBuilder
    private func segmentLabel(
        for item: NXSegmentItem<Selection>,
        isActive: Bool
    ) -> some View {
        let iconFont: Font = showLabels ? .subheadline.weight(.medium) : .body.weight(.medium)
        let iconScale: Image.Scale = showLabels ? .small : .medium
        let customSize: CGFloat = showLabels ? 13 : 18
        let hSpacing: CGFloat = showLabels ? 5 : 0
        let hPad: CGFloat = showLabels ? 12 : 10
        let vPad: CGFloat = showLabels ? 6 : 7

        HStack(spacing: hSpacing) {
            // Leading graphic — content takes precedence, then icon, then image
            if let content = item.content {
                switch content {
                case .icon(let name):
                    Image(systemName: name)
                        .font(iconFont)
                        .imageScale(iconScale)
                case .animatedIcon(let name, let animation):
                    switch animation {
                    case .bounce:
                        Image(systemName: name)
                            .font(iconFont)
                            .imageScale(iconScale)
                            .symbolEffect(.bounce, value: isActive)
                    case .pulse:
                        Image(systemName: name)
                            .font(iconFont)
                            .imageScale(iconScale)
                            .symbolEffect(.pulse, isActive: isActive)
                    case .variable:
                        Image(systemName: name)
                            .font(iconFont)
                            .imageScale(iconScale)
                            .symbolEffect(.variableColor, isActive: isActive)
                    }
                case .custom(let view):
                    view
                        .frame(height: customSize)
                        .frame(minWidth: showLabels ? 13 : nil)
                }
            } else if let symbolName = item.icon {
                Image(systemName: symbolName)
                    .font(iconFont)
                    .imageScale(iconScale)
            } else if let imageName = item.image {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: customSize, height: customSize)
            }

            if showLabels {
                Text(item.label)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, hPad)
        .padding(.vertical, vPad)
        .foregroundStyle(isActive ? Color.white : Color.secondary)
        // Keep the active label on top so the pill doesn't clip the text rendering
        .zIndex(isActive ? 1 : 0)
    }

    @ViewBuilder
    private func pillBackground(isActive: Bool) -> some View {
        if isActive {
            Capsule(style: .continuous)
                .fill(Color.effectiveAccent)
                .matchedGeometryEffect(id: "NXSegmentPill", in: pillNamespace)
        } else {
            // An invisible placeholder keeps the geometry effect anchor stable
            Capsule(style: .continuous)
                .fill(Color.clear)
                .matchedGeometryEffect(id: "NXSegmentPill", in: pillNamespace)
                .hidden()
        }
    }
}

// MARK: - Convenience initialisers

extension NXSegmentedControl {

    /// Creates a control from plain `(label, value)` tuples — no icons.
    init(items: [(label: String, value: Selection)], selection: Binding<Selection>, showLabels: Bool = true) {
        self.items = items.map { NXSegmentItem(label: $0.label, value: $0.value) }
        self._selection = selection
        self.showLabels = showLabels
    }

    /// Creates a control from `(label, value, icon)` tuples — static SF Symbol per segment.
    init(items: [(label: String, value: Selection, icon: String)], selection: Binding<Selection>, showLabels: Bool = true) {
        self.items = items.map { NXSegmentItem(label: $0.label, value: $0.value, content: .icon($0.icon)) }
        self._selection = selection
        self.showLabels = showLabels
    }
}

// MARK: - Preview

#Preview("Text only") {
    struct PreviewWrapper: View {
        @State private var selection = 0
        var body: some View {
            NXSegmentedControl(
                items: [
                    (label: "Default", value: 0),
                    (label: "Inline",  value: 1),
                    (label: "Minimal", value: 2),
                ],
                selection: $selection
            )
            .padding()
        }
    }
    return PreviewWrapper()
}

#Preview("Icon variant") {
    struct PreviewWrapper: View {
        enum Layout { case grid, list }
        @State private var layout = Layout.grid
        var body: some View {
            NXSegmentedControl(
                items: [
                    NXSegmentItem(label: "Grid", value: Layout.grid, icon: "square.grid.2x2"),
                    NXSegmentItem(label: "List", value: Layout.list, icon: "list.bullet"),
                ],
                selection: $layout
            )
            .padding()
        }
    }
    return PreviewWrapper()
}
