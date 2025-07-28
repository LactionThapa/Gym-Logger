import FirebaseAuth
import FirebaseFirestore

class FriendManager: ObservableObject {
    @Published var friends: [Friend] = []

    private let db = Firestore.firestore()

    func fetchFriends() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).collection("friends").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            self.friends = documents.compactMap { doc in
                let data = doc.data()
                guard let name = data["name"] as? String,
                      let since = (data["since"] as? Timestamp)?.dateValue() else { return nil }
                return Friend(id: doc.documentID, name: name, since: since)
            }
        }
    }

    func addFriend(byFriendID friendID: String, name: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let data: [String: Any] = [
            "name": name,
            "since": Date()
        ]

        db.collection("users")
            .document(uid)
            .collection("friends")
            .document(friendID)
            .setData(data)
    }

    func removeFriend(friendID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users")
            .document(uid)
            .collection("friends")
            .document(friendID)
            .delete()
    }
}
