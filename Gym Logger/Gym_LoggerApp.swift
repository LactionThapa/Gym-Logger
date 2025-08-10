import SwiftUI
import Firebase
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        return true
    }
}

@main
struct Gym_LoggerApp: App {
    @StateObject private var achievementManager: AchievementManager
    @StateObject private var workoutStorage: WorkoutStorage
    @StateObject private var templateStorage = WorkoutTemplateStorage()
    @StateObject private var exerciseLibrary = ExerciseLibraryStorage()
    @StateObject private var userProfileManager: UserProfileManager
    @StateObject private var friendManager = FriendManager()
    @StateObject private var authManager = AuthManager()
    @StateObject private var avatarManager = AvatarManager()
    
    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        let profileManager = UserProfileManager()
        let achievementMgr = AchievementManager.sharedInstance
        let workoutStore = WorkoutStorage(
            achievementManager: achievementMgr,
            profileManager: profileManager
        )
        
        _achievementManager = StateObject(wrappedValue: achievementMgr)
        _userProfileManager = StateObject(wrappedValue: profileManager)
        _workoutStorage = StateObject(wrappedValue: workoutStore)
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "AppBackground") ?? .black
        UITabBar.appearance().tintColor = UIColor(named: "F9AA33") ?? .systemOrange
        UITabBar.appearance().unselectedItemTintColor = .gray
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some Scene {
        WindowGroup {
            LevelUpOverlayContainer {
                AchievementOverlayContainer {
                    WorkoutSummaryOverlayContainer {
                        MainContainerView()
                    }
                }
            }
            .environmentObject(workoutStorage)
            .environmentObject(templateStorage)
            .environmentObject(exerciseLibrary)
            .environmentObject(achievementManager)
            .environmentObject(userProfileManager) // same instance as in WorkoutStorage
            .environmentObject(friendManager)
            .environmentObject(authManager)
            .environmentObject(avatarManager)
        }
    }
}



