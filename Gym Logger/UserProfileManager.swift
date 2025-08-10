import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI
struct LevelUpEvent: Identifiable, Equatable {
    let id = UUID()
    let newLevel: Int
}
class UserProfileManager: ObservableObject {
    @Published var profile = UserProfile()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    
    @Published var leveledUpRecently: LevelUpEvent? = nil
    
    
    @Published var lastWorkoutSummary: WorkoutSummary?

    
    var userID: String? {
            Auth.auth().currentUser?.uid
        }
    
    init() {
        signInIfNeeded()
        fetchUserProfile()
    }
    
    private func userRef() -> DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid)
    }
    
    func fetchUserProfile() {
        guard let ref = userRef() else { return }
        
        listener = ref.addSnapshotListener { snapshot, error in
            guard let data = snapshot?.data() else { return }
            
            if let decoded = try? Firestore.Decoder().decode(UserProfile.self, from: data) {
                DispatchQueue.main.async {
                    self.profile = decoded
                }
            }
        }
    }
    
    func updateName(_ name: String) {
        profile.profileName = name
        save()
    }
    
    func addXP(_ amount: Int) {
        let oldLevel = profile.level

        profile.xp += amount
        while profile.xp >= requiredXPForNextLevel {
            profile.xp -= requiredXPForNextLevel
            profile.level += 1
        }

        if profile.level > oldLevel {
            DispatchQueue.main.async {
                self.leveledUpRecently = LevelUpEvent(newLevel: self.profile.level)
            }
        }

        logXPGain(amount)

        guard let ref = userRef() else { return }
        ref.updateData([
            "xp": profile.xp,
            "level": profile.level
        ]) { err in
            if let err = err { print("❌ XP update failed: \(err)") }
            else { print("✅ XP/level updated (partial write)") }
        }
    }

    private func logXPGain(_ amount: Int) {
        guard let ref = userRef() else { return }
        let xpEvent: [String: Any] = [
            "xp": amount,
            "timestamp": Timestamp(date: Date())
        ]

        ref.updateData([
            "xpGains": FieldValue.arrayUnion([xpEvent])
        ]) { error in
            if let error = error {
                print("Failed to log XP gain: \(error.localizedDescription)")
            }
        }

        ref.getDocument { snapshot, _ in
            guard var xpGains = snapshot?.data()?["xpGains"] as? [[String: Any]] else { return }

            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            xpGains = xpGains.filter {
                guard let ts = $0["timestamp"] as? Timestamp else { return false }
                return ts.dateValue() >= thirtyDaysAgo
            }

            ref.updateData(["xpGains": xpGains])
        }

    }

    var currentXPIntoLevel: Int {
        var xpLeft = profile.xp
        var l = 1
        while xpLeft >= Int(100 * pow(1.5, Double(l - 1))) {
            xpLeft -= Int(100 * pow(1.5, Double(l - 1)))
            l += 1
        }
        return xpLeft
    }
    
    var requiredXPForNextLevel: Int {
        100 + (profile.level - 1) * 50
    }
    
    func unlockAchievement(_ id: String) {
        guard !profile.achievements.contains(id) else { return }
        profile.achievements.append(id)
        save()
    }
    
    func uploadProfileImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid,
              let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Missing UID or image data")
            completion(nil)
            return
        }

        let ref = storage.reference().child("profile_pics/\(uid).jpg")
        print("📤 Uploading image to Storage for UID: \(uid)")

        ref.putData(data, metadata: nil) { _, error in
            if let error = error {
                print("❌ Upload error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            ref.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }

                if let url = url {
                    print("✅ Image uploaded. URL: \(url.absoluteString)")

                    DispatchQueue.main.async {
                        self.profile.profilePicURL = url.absoluteString
                        print("📝 Saving profile with new image URL...")
                        self.save()
                        completion(url.absoluteString)
                    }
                }
            }
        }
    }

    func save() {
        guard let ref = userRef() else {
            print("❌ Could not get userRef")
            return
        }

        let payload: [String: Any] = [
            "username": profile.username,
            "profileName": profile.profileName,
            "profilePicURL": profile.profilePicURL as Any,
            "xp": profile.xp,
            "level": profile.level,
            "achievements": profile.achievements,
            "currentStreak": profile.currentStreak,
            "longestStreak": profile.longestStreak,
            "lastWorkoutDate": profile.lastWorkoutDate as Any
        ]

        print("⬆️ Writing payload:", payload)

        ref.setData(payload, merge: true) { error in
            if let error = error {
                print("❌ Firestore write error:", error)
            } else {
                print("✅ Firestore write OK")
            }
        }
    }

    deinit {
        listener?.remove()
    }
    func getCurrentProfileData() async throws -> [String: Any]? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        let snapshot = try await db.collection("users").document(uid).getDocument()
        return snapshot.data()
    }

    func setProfileData(_ data: [String: Any]) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(uid).setData(data, merge: true)
    }
    func reset() {
        self.profile = UserProfile() // default empty profile
    }
    
    func updateStreak(_ workoutDate: Date) {
        guard let ref = userRef() else { return }
        let cal = Calendar.current

        var current = profile.currentStreak
        var longest = profile.longestStreak

        if let last = profile.lastWorkoutDate {
            // If same day, keep streak; still refresh lastWorkoutDate for consistency
            if !cal.isDate(workoutDate, inSameDayAs: last) {
                let startLast = cal.startOfDay(for: last)
                let startNow  = cal.startOfDay(for: workoutDate)
                let days = cal.dateComponents([.day], from: startLast, to: startNow).day ?? 0

                if days == 1 {
                    current += 1
                } else if days > 1 {
                    current = 1
                }
            }
        } else {
            // First workout ever
            current = 1
            longest = max(longest, current)
        }

        if current > longest { longest = current }

        // Update local cache
        profile.currentStreak = current
        profile.longestStreak = longest
        profile.lastWorkoutDate = workoutDate

        print("🔥 Streak update only → current=\(current), longest=\(longest), last=\(workoutDate)")

        // **Partial write** so XP/other fields are untouched
        ref.updateData([
            "currentStreak": current,
            "longestStreak": longest,
            "lastWorkoutDate": Timestamp(date: workoutDate)
        ]) { err in
            if let err = err {
                print("❌ Failed to update streak fields: \(err)")
            } else {
                print("✅ Streak fields updated (partial write)")
            }
        }
    }
    func setDiscoverable(_ value: Bool) {
            profile.isDiscoverable = value
            let uid = Auth.auth().currentUser?.uid ?? ""
            Firestore.firestore().collection("users").document(uid)
                .setData(["isDiscoverable": value], merge: true)
        }
}
