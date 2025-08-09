import SwiftUI

struct WorkoutSummaryOverlayContainer<Content: View>: View {
    @EnvironmentObject var userProfileManager: UserProfileManager
    @State private var summary: WorkoutSummary?
    @State private var visible = false

    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            content

            if let s = summary, visible {
                // Dimmed backdrop that matches your dark theme
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // Centered card
                WorkoutSummaryCard(summary: s) { dismiss() }
                    .frame(maxWidth: 360)
                    .transition(.scale.combined(with: .opacity))
                    .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
            }
        }
        .onReceive(userProfileManager.$lastWorkoutSummary) { newValue in
            guard let newValue else { return }
            DispatchQueue.main.async {
                summary = newValue
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    visible = true
                }
                // No auto-dismiss; user taps X to close
            }
        }
    }

    private func dismiss() {
        let gen = UIImpactFeedbackGenerator(style: .medium)
        gen.impactOccurred()

        withAnimation(.easeInOut(duration: 0.25)) {
            visible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            summary = nil
            userProfileManager.lastWorkoutSummary = nil
        }
    }
}
