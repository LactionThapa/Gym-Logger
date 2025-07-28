import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class UserProfileManager: ObservableObject {
    @Published var profile = UserProfile(profileName: "", xp: 0, profilePicURL: nil, achievements: [])

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

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
            if let data = snapshot?.data(),
               let profile = try? Firestore.Decoder().decode(UserProfile.self, from: data) {
                DispatchQueue.main.async {
                    self.profile = profile
                }
            }
        }
    }

    func updateName(_ name: String) {
        userRef()?.updateData(["profileName": name])
    }

    func addXP(_ amount: Int) {
        userRef()?.updateData(["xp": FieldValue.increment(Int64(amount))])
    }

    func unlockAchievement(_ id: String) {
        userRef()?.updateData(["achievements": FieldValue.arrayUnion([id])])
    }

    func uploadProfileImage(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid,
              let data = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        let ref = storage.reference().child("profile_pics/\(uid).jpg")
        ref.putData(data, metadata: nil) { _, error in
            guard error == nil else {
                completion(nil)
                return
            }
            ref.downloadURL { url, _ in
                if let url = url {
                    self.userRef()?.updateData(["profilePicURL": url.absoluteString])
                    DispatchQueue.main.async {
                        self.profile.profilePicURL = url.absoluteString
                    }
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }

    deinit {
        listener?.remove()
    }
}
