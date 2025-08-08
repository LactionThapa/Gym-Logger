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

    func evaluateAchievements(using workouts: [Workout], onUnlock: @escaping (Achievement) -> Void) {
        let workoutCount = workouts.count
        let totalWeight = workouts
            .flatMap { $0.exercises }
            .reduce(0.0) { $0 + ($1.weight * Double($1.sets.count)) }

        for i in achievements.indices {
            if achievements[i].earned { continue }

            var shouldUnlock = false
            switch achievements[i].title {
            case "First Workout": shouldUnlock = workoutCount >= 1
            case "25 Workouts":    shouldUnlock = workoutCount >= 25
            case "50 Workouts":    shouldUnlock = workoutCount >= 50
            case "75 Workouts":    shouldUnlock = workoutCount >= 75
            case "100 Workouts":    shouldUnlock = workoutCount >= 100
            case "10,000 KG Lifted": shouldUnlock = totalWeight >= 10_000
            default: break
            }

            if shouldUnlock {
                achievements[i].earned = true
                achievements[i].dateEarned = Date()
                saveAchievementToFirestore(achievements[i])

                // 🔔 Trigger UI popup
                DispatchQueue.main.async {
                    self.unlockedRecently = self.achievements[i]
                }
            }
        }
    }

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
            Achievement(id: "firstWorkout", title: "First Workout", description: "Log your first workout.", imageName: "1.circle"),
            Achievement(id: "25Workouts", title: "25 Workouts", description: "Log 25 workouts.", imageName: "25.circle"),
            Achievement(id: "50Workouts", title: "50 Workouts", description: "Log 50 workouts.", imageName: "50.circle"),
            Achievement(id: "75Workouts", title: "75 Workouts", description: "Log 75 workouts.", imageName: "75.circle"),
            Achievement(id: "100Workouts", title: "100 Workouts", description: "Log 100 workouts.", imageName: "100.circle"),
            Achievement(id: "tenKiloLifted", title: "10,000 KG Lifted", description: "Lift a total of 10,000 kg.", imageName: "scalemass")
        ]
    }
    func reset() {
        self.achievements = self.defaultAchievements()
    }

    deinit {
        listener?.remove()
    }
}
