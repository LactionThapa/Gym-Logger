import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class UserProfileManager: ObservableObject {
    @Published var profile = UserProfile()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?
    
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
        profile.xp += amount
        while profile.xp >= requiredXPForNextLevel {
            profile.xp -= requiredXPForNextLevel
            profile.level += 1
        }
        
        logXPGain(amount)
        save()
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

        do {
            try ref.setData(from: profile)
            print("✅ Profile saved to Firestore.")
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
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
}
