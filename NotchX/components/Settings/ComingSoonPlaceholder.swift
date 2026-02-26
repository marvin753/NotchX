//
//  ComingSoonPlaceholder.swift
//  NotchX
//

import SwiftUI

struct ComingSoonPlaceholder: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2.weight(.semibold))

            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Text("Coming Soon")
                .font(.footnote.bold())
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color(nsColor: .secondarySystemFill))
                .clipShape(Capsule())
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
