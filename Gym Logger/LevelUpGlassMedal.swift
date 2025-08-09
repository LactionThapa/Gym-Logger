import SwiftUI
struct LevelUpGlassMedal: View {
    let level: Int
    var autoDismissAfter: Double = 2.0
    let onDismiss: () -> Void

    @State private var pop = false
    @State private var glow = false

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(.ultraThinMaterial)
                        .frame(width: 96, height: 96)
                        .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
                        .shadow(radius: 18, y: 6)

                    Image(systemName: "medal.fill")
                        .font(.system(size: 44))
                        .scaleEffect(pop ? 1 : 0.6)
                        .shadow(radius: glow ? 14 : 0)
                }

                Text("Level Up!")
                    .font(.title3.weight(.bold))
                Text("You reached level \(level)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Nice!") { onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
            }
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            .padding(.horizontal, 24)
            Spacer()
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { pop = true }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) { glow = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) { onDismiss() }
        }
    }
}
