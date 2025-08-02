import Foundation
import FirebaseAuth
import FirebaseFirestore

class FriendManager: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var incomingRequests: [String] = [] // Friend request sender UIDs
    
    private let db = Firestore.firestore()
    
    // MARK: - Fetch Friends
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
    
    func fetchFriendIDs(completion: @escaping ([String]) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection("users").document(uid).collection("friends").getDocuments { snapshot, error in
            let ids = snapshot?.documents.map { $0.documentID } ?? []
            completion(ids)
        }
    }
    
    func removeFriend(friendID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .collection("friends")
            .document(friendID)
            .delete()
        db.collection("users")
            .document(friendID)
            .collection("friends")
            .document(uid)
            .delete()
    }
    
    // MARK: - Send Friend Request by Username
    func sendFriendRequest(toUsername: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        db.collection("usernames").document(toUsername).getDocument { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  let targetUserID = snapshot.data()?["userId"] as? String else {
                completion(.failure(NSError(domain: "FriendManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                return
            }
            
            if targetUserID == currentUserID {
                completion(.failure(NSError(domain: "FriendManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "You can't add yourself."])))
                return
            }
            
            // Check if already friends
            self.db.collection("users")
                .document(currentUserID)
                .collection("friends")
                .document(targetUserID)
                .getDocument { snapshot, _ in
                    if snapshot?.exists == true {
                        completion(.failure(NSError(domain: "FriendManager", code: 409, userInfo: [NSLocalizedDescriptionKey: "Already friends."])))
                        return
                    }
                    
                    // Send friend request
                    let requestData: [String: Any] = [
                        "from": currentUserID,
                        "timestamp": FieldValue.serverTimestamp()
                    ]
                    
                    self.db.collection("users")
                        .document(targetUserID)
                        .collection("friendRequests")
                        .document(currentUserID)
                        .setData(requestData) { error in
                            if let error = error {
                                completion(.failure(error))
                            } else {
                                completion(.success(()))
                            }
                        }
                    self.db.collection("users")
                        .document(currentUserID)
                        .collection("sentRequests")
                        .document(targetUserID)
                        .setData([
                            "username": toUsername,
                            "timestamp": FieldValue.serverTimestamp()
                        ])
                }
        }
    }
    
    // MARK: - Incoming Friend Requests
    func fetchIncomingRequests() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users")
            .document(uid)
            .collection("friendRequests")
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self.incomingRequests = docs.map { $0.documentID }
            }
    }
    func fetchSentRequests(completion: @escaping (Set<String>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        db.collection("users")
            .document(uid)
            .collection("sentRequests")
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    let usernames = documents.compactMap { $0.data()["username"] as? String }
                    completion(Set(usernames))
                } else {
                    completion([])
                }
            }
    }
    
    
    // MARK: - Accept/Reject Friend Request
    func acceptFriendRequest(fromUserID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let currentUserRef = db.collection("users").document(currentUserID)
        let otherUserRef = db.collection("users").document(fromUserID)
        let timestamp = Timestamp()
        
        var currentUsername = "You"
        var otherUsername = "Friend"
        
        let group = DispatchGroup()
        
        group.enter()
        currentUserRef.getDocument { snapshot, _ in
            if let name = snapshot?.data()?["profileName"] as? String {
                currentUsername = name
            }
            group.leave()
        }
        
        group.enter()
        otherUserRef.getDocument { snapshot, _ in
            if let name = snapshot?.data()?["profileName"] as? String {
                otherUsername = name
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Add each other to friends
            currentUserRef.collection("friends").document(fromUserID).setData([
                "name": otherUsername,
                "since": timestamp
            ])
            
            otherUserRef.collection("friends").document(currentUserID).setData([
                "name": currentUsername,
                "since": timestamp
            ])
            
            // Remove the request from current user's incoming
            currentUserRef.collection("friendRequests").document(fromUserID).delete()
            
            // 🔥 Remove from sender's sentRequests
            otherUserRef.collection("sentRequests").document(currentUserID).delete()
        }
    }

    
    func rejectFriendRequest(fromUserID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        let currentUserRef = db.collection("users").document(currentUserID)
        let senderRef = db.collection("users").document(fromUserID)
        
        // Remove the request from receiver's incoming
        currentUserRef.collection("friendRequests").document(fromUserID).delete()
        
        // 🔥 Also remove the sent request from sender
        senderRef.collection("sentRequests").document(currentUserID).delete()
    }

    
    // MARK: - Fetch Usernames for Display
    func fetchUsernames(for ids: [String], completion: @escaping ([String: String]) -> Void) {
        var result: [String: String] = [:]
        let group = DispatchGroup()
        
        for id in ids {
            group.enter()
            db.collection("users").document(id).getDocument { snapshot, error in
                if let data = snapshot?.data(), let username = data["username"] as? String {
                    result[id] = username
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(result)
        }
    }
    func lookupUserID(forUsername username: String, completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("usernames").document(username).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
            } else if let userID = snapshot?.data()?["userId"] as? String {
                completion(.success(userID))
            } else {
                completion(.failure(NSError(domain: "FriendManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
            }
        }
    }
    func getUsername(forUserID userID: String, completion: @escaping (String?) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore error: \(error)")
            }
            
            if let data = snapshot?.data(), let username = data["username"] as? String {
                completion(username)
            } else {
                print("⚠️ No username found for ID \(userID)")
                completion(nil)
            }
        }
    }
}
