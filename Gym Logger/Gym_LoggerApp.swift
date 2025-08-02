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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var workoutStorage = WorkoutStorage()
    @StateObject private var templateStorage = WorkoutTemplateStorage()
    @StateObject private var exerciseLibrary = ExerciseLibraryStorage()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var userProfileManager = UserProfileManager()
    @StateObject var friendManager = FriendManager()
        
    @StateObject var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            MainContainerView()
                .environmentObject(workoutStorage)
                .environmentObject(AchievementManager.sharedInstance)
                .environmentObject(templateStorage)
                .environmentObject(exerciseLibrary)
                .environmentObject(achievementManager)
                .environmentObject(userProfileManager)
                .environmentObject(friendManager)
                .environmentObject(authManager)
        }
    }
}
