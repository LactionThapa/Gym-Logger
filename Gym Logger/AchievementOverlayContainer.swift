import SwiftUI
struct AchievementOverlayContainer<Content: View>: View {
    @EnvironmentObject var achievementManager: AchievementManager
    @State private var showPopup = false
    @State private var currentAchievement: Achievement?

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            content

            // Popup overlay
            if let achievement = currentAchievement, showPopup {
                VStack {
                    AchievementUnlockedView(achievement: achievement, isVisible: $showPopup)
                        .padding(.top, 60) // drop it below the status bar
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .onReceive(achievementManager.$unlockedRecently) { newValue in
            if let ach = newValue {
                currentAchievement = ach
                withAnimation(.spring()) { showPopup = true }
                // Reset in the manager after we start showing
                achievementManager.dismissCurrentPopup()
            }
        }
    }
}
