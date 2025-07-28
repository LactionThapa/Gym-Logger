import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var userProfileManager: UserProfileManager
    @EnvironmentObject var friendManager: FriendManager
    
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            TabView {
                TemplateListView().tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Workout")
                }
                WorkoutHistoryView().tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                UserProfileView().tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                FriendsListView().tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                FriendLeaderboardView().tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }
            }

            // ✅ Global popup shown from AchievementManager
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
    MainTabView()
        .environmentObject(WorkoutStorage())
        .environmentObject(WorkoutTemplateStorage())
        .environmentObject(ExerciseLibraryStorage())
        .environmentObject(AchievementManager())
        .environmentObject(UserProfileManager())
        .environmentObject(FriendManager())
        .environmentObject(AuthManager())
}
