//
//  NotchShape.swift
//  NotchX
//
// Created by Kai Azim on 2023-08-24.
// Original source: https://github.com/MrKai77/DynamicNotchKit
// Modified by Alexander on 2025-05-18.

import SwiftUI

struct NotchShape: Shape {
    private var topCornerRadius: CGFloat
    private var bottomCornerRadius: CGFloat

    init(
        topCornerRadius: CGFloat? = nil,
        bottomCornerRadius: CGFloat? = nil
    ) {
        self.topCornerRadius = topCornerRadius ?? 6
        self.bottomCornerRadius = bottomCornerRadius ?? 14
    }

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            .init(
                topCornerRadius,
                bottomCornerRadius
            )
        }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        guard rect.width > 0, rect.height > 0 else {
            return Path()
        }

        let safeTopCornerRadius = max(
            0,
            min(
                topCornerRadius,
                rect.width / 2,
                rect.height
            )
        )
        let safeBottomCornerRadius = max(
            0,
            min(
                bottomCornerRadius,
                rect.width / 2 - safeTopCornerRadius,
                rect.height - safeTopCornerRadius
            )
        )

        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + safeTopCornerRadius,
                y: rect.minY + safeTopCornerRadius
            ),
            control: CGPoint(
                x: rect.minX + safeTopCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX + safeTopCornerRadius,
                y: rect.maxY - safeBottomCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.minX + safeTopCornerRadius + safeBottomCornerRadius,
                y: rect.maxY
            ),
            control: CGPoint(
                x: rect.minX + safeTopCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - safeTopCornerRadius - safeBottomCornerRadius,
                y: rect.maxY
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX - safeTopCornerRadius,
                y: rect.maxY - safeBottomCornerRadius
            ),
            control: CGPoint(
                x: rect.maxX - safeTopCornerRadius,
                y: rect.maxY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.maxX - safeTopCornerRadius,
                y: rect.minY + safeTopCornerRadius
            )
        )

        path.addQuadCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.minY
            ),
            control: CGPoint(
                x: rect.maxX - safeTopCornerRadius,
                y: rect.minY
            )
        )

        path.addLine(
            to: CGPoint(
                x: rect.minX,
                y: rect.minY
            )
        )

        return path
    }
}

#Preview {
    NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
        .frame(width: 200, height: 32)
        .padding(10)
}
