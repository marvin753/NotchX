import SwiftUI

@MainActor
struct NotchLockButton: View {
    @Binding var isLocked: Bool
    @State private var isHoveringZone: Bool = false

    private var isVisible: Bool {
        isHoveringZone || isLocked
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear
                .frame(width: 80, height: 60)
                .contentShape(Rectangle())

            Button {
                isLocked.toggle()
            } label: {
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.bounce, value: isLocked)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.black.opacity(0.6))
                            .blur(radius: 8)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .animation(.easeInOut(duration: 0.2), value: isVisible)
            .padding(.trailing, 3)
            .padding(.bottom, -10)
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHoveringZone = hovering
            }
        }
    }
}
