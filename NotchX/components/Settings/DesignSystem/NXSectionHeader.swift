//
//  NXSectionHeader.swift
//  NotchX
//
//  A consistent section header component for settings pages.
//  Supports an optional badge (e.g. "Beta", "Coming soon") and an optional subtitle.
//

import SwiftUI

struct NXSectionHeader: View {
    let title: String
    var badge: String? = nil
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.headline)

                if let badge {
                    Text(badge)
                        .foregroundStyle(.secondary)
                        .font(.footnote.bold())
                        .padding(.vertical, 3)
                        .padding(.horizontal, 6)
                        .background(Color(nsColor: .secondarySystemFill))
                        .clipShape(.capsule)
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        NXSectionHeader(title: "General")
        NXSectionHeader(title: "Appearance", badge: "Beta")
        NXSectionHeader(title: "Music", subtitle: "Configure how music is displayed in the notch.")
    }
    .padding()
    .frame(width: 320)
}
