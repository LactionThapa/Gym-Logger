import SwiftUI

struct AchievementUnlockedView: View {
    let achievement: Achievement
    @Binding var isVisible: Bool
    @State private var offsetY: CGFloat = -200
    @State private var showConfetti = false

    var body: some View {
        if isVisible {
            ZStack {
                // Confetti burst
                if showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                        .zIndex(0)
                }

                // Popup Card
                VStack(spacing: 12) {
                    Image(systemName: achievement.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.yellow)
                        .shadow(radius: 4)

                    Text("Achievement Unlocked!")
                        .font(.headline)
                        .bold()

                    Text(achievement.title)
                        .font(.subheadline)
                        .padding(.bottom, 10)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .shadow(radius: 10)
                .offset(y: offsetY)
                .zIndex(1)
            }
            .onAppear {
                // Slide & bounce in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    offsetY = 0
                }

                // Confetti & haptics
                showConfetti = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)

                // Auto-hide
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        offsetY = -200
                        showConfetti = false
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                    isVisible = false
                }
            }
        }
    }
}
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .onAppear {
                        withAnimation(.easeOut(duration: particle.duration)) {
                            particle.position.y += CGFloat.random(in: 200...400)
                            particle.opacity = 0
                        }
                    }
            }
        }
        .onAppear {
            // Generate particles once
            particles = (0..<20).map { _ in ConfettiParticle() }
        }
    }
}

class ConfettiParticle: Identifiable {
    let id = UUID()
    var position = CGPoint(x: CGFloat.random(in: 50...350), y: CGFloat.random(in: 50...150))
    var color = [Color.red, Color.blue, Color.green, Color.yellow, Color.purple, Color.orange].randomElement()!
    var duration = Double.random(in: 1.0...1.8)
    var opacity: Double = 1
}
