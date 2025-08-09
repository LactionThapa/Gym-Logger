import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []
    @Published var unlockedRecently: Achievement? = nil

    private let db = Firestore.firestore()
    private let collectionKey = "achievements"
    private var listener: ListenerRegistration?
    static let sharedInstance = AchievementManager()
    
    private var queue: [Achievement] = []
    

    init() {
        loadAchievements()
    }
    
    func loadAchievements() {
        guard let userID = Auth.auth().currentUser?.uid else {
                print("❌ No user ID available when loading achievements.")
                return
            }
        print("📥 Loading achievements for user: \(userID)")
        listener?.remove() 

        listener = db.collection("users")
            .document(userID)
            .collection(collectionKey)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ Failed to load achievements: \(error.localizedDescription)")
                    self.achievements = self.defaultAchievements() // fallback
                    return
                }

                var loaded: [Achievement] = self.defaultAchievements()

                snapshot?.documents.forEach { doc in
                    if let index = loaded.firstIndex(where: { $0.id == doc.documentID }),
                       let earned = doc.data()["earned"] as? Bool,
                       let timestamp = doc.data()["dateEarned"] as? Timestamp {
                        loaded[index].earned = earned
                        loaded[index].dateEarned = timestamp.dateValue()
                    }
                }

                DispatchQueue.main.async {
                    self.achievements = loaded
                }
            }
    }
    
    func evaluateAchievements(
        using workouts: [Workout],
        currentStreak: Int,
        onUnlock: @escaping (Achievement) -> Void
    ) {
        let workoutCount = workouts.count
        let totalWeight = workouts
            .flatMap { $0.exercises }
            .reduce(0.0) { $0 + ($1.weight * Double($1.sets.count)) }

        var newlyUnlocked: [Achievement] = []

        for i in achievements.indices where !achievements[i].earned {
            let a = achievements[i]
            var shouldUnlock = false

            switch a.id {
            // workout-count
            case "firstWorkout": shouldUnlock = workoutCount >= 1
            case "25Workouts":   shouldUnlock = workoutCount >= 25
            case "50Workouts":   shouldUnlock = workoutCount >= 50
            case "75Workouts":   shouldUnlock = workoutCount >= 75
            case "100Workouts":  shouldUnlock = workoutCount >= 100

            // volume
            case "tenKiloLifted": shouldUnlock = totalWeight >= 10_000

            // streaks
            case "streak_3":   shouldUnlock = currentStreak >= 3
            case "streak_7":   shouldUnlock = currentStreak >= 7
            case "streak_14":  shouldUnlock = currentStreak >= 14
            case "streak_30":  shouldUnlock = currentStreak >= 30
            case "streak_60":  shouldUnlock = currentStreak >= 60
            case "streak_90":  shouldUnlock = currentStreak >= 90
            case "streak_180": shouldUnlock = currentStreak >= 180
            case "streak_365": shouldUnlock = currentStreak >= 365

            default: break
            }

            if shouldUnlock {
                achievements[i].earned = true
                achievements[i].dateEarned = Date()
                saveAchievementToFirestore(achievements[i])
                newlyUnlocked.append(achievements[i])
            }
        }

        if !newlyUnlocked.isEmpty {
            queue.append(contentsOf: newlyUnlocked)
            schedulePresentation()
        }
    }

    private func schedulePresentation() {
        guard unlockedRecently == nil, !queue.isEmpty else { return }
        Task { @MainActor in
            // small delay so we never collide with the navigation pop animation
            try? await Task.sleep(nanoseconds: 150_000_000)
            self.unlockedRecently = self.queue.removeFirst()
        }
    }

        // Call this from the sheet's "OK" button
        func dismissCurrentPopup() {
            unlockedRecently = nil
            schedulePresentation() // show next one if any
        }
    //end new

    private func saveAchievementToFirestore(_ achievement: Achievement) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "earned": achievement.earned,
            "dateEarned": achievement.dateEarned ?? FieldValue.serverTimestamp()
        ]

        db.collection("users")
            .document(userID)
            .collection(collectionKey)
            .document(achievement.id)
            .setData(data, merge: true)
    }

    func defaultAchievements() -> [Achievement] {
        return [
            // Existing
            Achievement(id: "firstWorkout", title: "First Workout", description: "Log your first workout.", imageName: "1.circle"),
            Achievement(id: "25Workouts", title: "25 Workouts", description: "Log 25 workouts.", imageName: "medal.fill"),
            Achievement(id: "50Workouts", title: "50 Workouts", description: "Log 50 workouts.", imageName: "rosette"),
            Achievement(id: "75Workouts", title: "75 Workouts", description: "Log 75 workouts.", imageName: "trophy.fill"),
            Achievement(id: "100Workouts", title: "100 Workouts", description: "Log 100 workouts.", imageName: "crown.fill"),
            Achievement(id: "tenKiloLifted", title: "10,000 KG Lifted", description: "Lift a total of 10,000 kg.", imageName: "scalemass"),
            Achievement(id: "streak_3",   title: "On a Roll",            description: "3-day streak.",   imageName: "flame.fill"),
            Achievement(id: "streak_7",   title: "One Week Wonder",      description: "7-day streak.",   imageName: "flame.circle.fill"),
            Achievement(id: "streak_14",  title: "Two-Week Warrior",     description: "14-day streak.",  imageName: "flame"),
            Achievement(id: "streak_30",  title: "30-Day Challenger",    description: "30-day streak.",  imageName: "bolt.fill"),
            Achievement(id: "streak_60",  title: "Two-Month Titan",      description: "60-day streak.",  imageName: "bolt.circle.fill"),
            Achievement(id: "streak_90",  title: "Quarter-Year Crusher", description: "90-day streak.",  imageName: "bolt"),
            Achievement(id: "streak_180", title: "Half-Year Hero",       description: "180-day streak.", imageName: "crown"),
            Achievement(id: "streak_365", title: "Year of the Beast",    description: "365-day streak.", imageName: "crown.fill")
        ]
    }


    func reset() {
        self.achievements = self.defaultAchievements()
    }

    deinit {
        listener?.remove()
    }
}
