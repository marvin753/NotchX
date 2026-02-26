//
//  SettingsSidebarLabel.swift
//  NotchX
//

import SwiftUI

struct SettingsSidebarLabel: View {
    let title: String
    let icon: String
    let color: Color
    var isComingSoon: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }

            Text(title)

            if isComingSoon {
                Spacer()
                Text("Soon")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .secondarySystemFill))
                    .clipShape(Capsule())
            }
        }
    }
}
