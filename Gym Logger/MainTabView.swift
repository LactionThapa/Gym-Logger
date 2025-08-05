import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var authManager: AuthManager
    
    var toggleSidebar: () -> Void
    
    var body: some View {
        ZStack {
            TabView {
                SidebarInjectingNavigationView(toggleSidebar: toggleSidebar) {
                    TemplateListView()
                }
                .tabItem {
                    Label("Log Workout", systemImage: "plus.circle.fill")
                }
                
                SidebarInjectingNavigationView(toggleSidebar: toggleSidebar) {
                    WorkoutHistoryView()
                }
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                
                SidebarInjectingNavigationView(toggleSidebar: toggleSidebar) {
                    FriendLeaderboardView()
                }
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
            }.accentColor(Color(hex:"F9AA33"))
            
            // 🏆 Achievement Popup
            if let unlocked = achievementManager.unlockedRecently {
                AchievementUnlockedView(achievement: unlocked, isVisible: .constant(true))
                    .transition(.scale)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            achievementManager.unlockedRecently = nil
                        }
                    }
                    .zIndex(1)
            }
        }
        
    }
    
}


#Preview {
    WorkoutBuilderView()
        .environmentObject(WorkoutStorage())
        .environmentObject(WorkoutTemplateStorage())
        .environmentObject(ExerciseLibraryStorage())
        .environmentObject(AchievementManager())
        .environmentObject(UserProfileManager())
        .environmentObject(FriendManager())
        .environmentObject(AuthManager())
}
