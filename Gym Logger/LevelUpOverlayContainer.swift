import SwiftUI
struct LevelUpOverlayContainer<Content: View>: View {
    @EnvironmentObject var profile: UserProfileManager
    @State private var currentLevel: Int?
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            content
            if let level = currentLevel {
                VStack {
                    LevelUpPopUp(level: level) {
                        currentLevel = nil
                        profile.leveledUpRecently = nil
                    }
                    .padding(.top, 12)
                    Spacer()
                }
                .zIndex(999)
            }
        }
        .onReceive(profile.$leveledUpRecently) { event in
            guard let event else { return }
            // present next tick so it never collides with an ongoing dismiss()
            DispatchQueue.main.async { currentLevel = event.newLevel }
        }
    }
}
