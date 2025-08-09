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
                // Dim background taps through except the card
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { dismiss() }

                VStack {
                    Spacer()
                    WorkoutSummaryCard(summary: s, onClose: dismiss)
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .shadow(radius: 20)
                }
                .zIndex(10)
            }
        }
        .onReceive(userProfileManager.$lastWorkoutSummary) { newValue in
            guard let newValue else { return }
            // Present on the next tick to avoid racing with any dismiss()
            DispatchQueue.main.async {
                summary = newValue
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    visible = true
                }
                // Auto-dismiss after 3s; tweak as you like
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    dismiss()
                }
            }
        }
    }

    private func dismiss() {
        guard visible else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            visible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            summary = nil
            userProfileManager.lastWorkoutSummary = nil
        }
    }
}
