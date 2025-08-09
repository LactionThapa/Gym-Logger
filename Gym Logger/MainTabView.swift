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
            }
            .accentColor(Color(hex: "F9AA33"))
        }
        
    }
    
}

#Preview {
    LevelUpOverlayContainer {
        AchievementOverlayContainer {
            WorkoutSummaryOverlayContainer {
                MainContainerView()
            }
        }
    }
        .environmentObject(
            WorkoutStorage(
                achievementManager: .sharedInstance,
                profileManager: UserProfileManager()   // inject one so streak code runs
            )
        )
        .environmentObject(WorkoutTemplateStorage())
        .environmentObject(ExerciseLibraryStorage())
        .environmentObject(AchievementManager.sharedInstance)
        .environmentObject(UserProfileManager())
        .environmentObject(FriendManager())
        .environmentObject(AuthManager())
}
