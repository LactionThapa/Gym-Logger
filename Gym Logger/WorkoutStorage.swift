import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

func signInIfNeeded() {
    if Auth.auth().currentUser == nil {
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                print("Login failed: \(error.localizedDescription)")
            }
        }
    }
}

class WorkoutStorage: ObservableObject {
    @Published var history: [Workout] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    var achievementManager: AchievementManager?
    private let key = "saved_workouts"
    
    init(achievementManager: AchievementManager = AchievementManager.sharedInstance) {
           self.achievementManager = achievementManager
           signInIfNeeded()
           load()
       }
    
    func save(workout: Workout) {
        guard let userID = Auth.auth().currentUser?.uid else { return }

        history.insert(workout, at: 0)
        let workoutDict = workout.toDictionary()

        db.collection("users")
            .document(userID)
            .collection("workouts")
            .document(workout.id.uuidString)
            .setData(workoutDict)

        persist()

        // ✅ Evaluate achievements using injected instance
        achievementManager?.evaluateAchievements(using: history) { newAchievement in
            DispatchQueue.main.async {
                self.achievementManager?.unlockedRecently = newAchievement
            }
        }
    }
    
    func delete(at offsets: IndexSet) {
        guard let userID = Auth.auth().currentUser?.uid else { return}
        
        for index in offsets {
            let workout = history[index]
            let workoutID = workout.id.uuidString
            db.collection("users")
                .document(userID)
                .collection("workouts")
                .document(workoutID)
                .delete()
        }
        history.remove(atOffsets: offsets)
        persist()
    }
    
    private func persist() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func load() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Workout].self, from: data) {
            self.history = saved
        }
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        listener = db.collection("users")
            .document(userID)
            .collection("workouts")
            .order(by: "date", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Failed to load workouts: \(error)")
                    return
                }
                
                self.history = snapshot?.documents.compactMap { doc -> Workout? in
                    guard var workout = Workout.fromDictionary(doc.data()) else {
                        return nil
                    }
                    workout.id = UUID(uuidString: doc.documentID) ?? UUID()
                    return workout
                } ?? []
                self.persist()
            }
    }
    func getAllWorkouts() async throws -> [(id: String, data: [String: Any])] {
        guard let uid = Auth.auth().currentUser?.uid else { return [] }
        let snapshot = try await db.collection("users").document(uid).collection("workouts").getDocuments()
        return snapshot.documents.map { ($0.documentID, $0.data()) }
    }

    func saveWorkouts(_ workouts: [(id: String, data: [String: Any])]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        for workout in workouts {
            try await db.collection("users").document(uid)
                .collection("workouts")
                .document(workout.id)
                .setData(workout.data)
        }
    }
    func delete(whereIDIn ids: [UUID]) {
        history.removeAll { ids.contains($0.id) }
    }
    func reset() {
        self.history = []
    }
    
    deinit {
        listener?.remove()
    }
}
