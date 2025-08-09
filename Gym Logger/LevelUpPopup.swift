import SwiftUI

struct LevelUpPopUp: View {
    let level: Int
    var autoDismissAfter: Double = 1.8
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.7
    @State private var fade = false

    var body: some View {
        ZStack {
            Color.black.opacity(fade ? 0.35 : 0).ignoresSafeArea()
            VStack(spacing: 14) {
                SimpleConfettiBurst() // light confetti; implement similar to your ConfettiView
                    .frame(height: 0)

                ZStack {
                    Circle().fill(.ultraThinMaterial).frame(width: 120, height: 120)
                    Image(systemName: "sparkles")
                        .font(.system(size: 54))
                }
                .scaleEffect(scale)

                Text("Level \(level)")
                    .font(.largeTitle.bold())
                Text("Nice work!").foregroundStyle(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 30)
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeIn(duration: 0.25)) { fade = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) { scale = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) { dismiss() }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.2)) { fade = false; scale = 0.8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { onDismiss() }
    }
}

struct SimpleConfettiBurst: View {
    @State private var particles: [Particle] = (0..<18).map { _ in Particle() }
    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: 6, height: 6)
                    .offset(x: p.dx, y: p.dy)
                    .opacity(p.opacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: p.duration)) {
                            p.dy += CGFloat.random(in: 120...240)
                            p.dx += CGFloat.random(in: -80...80)
                            p.opacity = 0
                        }
                    }
            }
        }.frame(height: 0)
    }
    final class Particle: Identifiable {
        let id = UUID()
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        var opacity: Double = 1
        let duration = Double.random(in: 0.8...1.4)
        let color = [Color.yellow, .orange, .pink, .mint, .blue, .purple].randomElement()!
    }
}

