import SwiftUI

struct LevelUpPopup: View {
    let level: Int
    var autoDismissAfter: Double = 2.0
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var showConfetti = false

    var body: some View {
        VStack {
            if isVisible {
                ZStack {
                    if showConfetti {
                        SimpleConfettiBurst()
                            .transition(.opacity)
                            .zIndex(0)
                    }
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(.ultraThinMaterial).frame(width: 56, height: 56)
                            Image(systemName: "star.fill").font(.title2)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Level Up!").font(.headline).bold()
                            Text("You reached level \(level)").font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { dismissNow() } label {
                            Image(systemName: "xmark").padding(8)
                        }
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 12)
                    .padding(.horizontal)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .onAppear {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
                showConfetti = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) { dismissNow() }
        }
    }

    private func dismissNow() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isVisible = false
            showConfetti = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26, execute: onDismiss)
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
