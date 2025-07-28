import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [AppUser] = []
    @EnvironmentObject var friendManager: FriendManager
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search by username", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                List(searchResults) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.profileName)
                            Text("@\(user.username)").font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Lv \(user.level)")
                        Text("\(user.xp) XP").font(.caption).foregroundColor(.green)
                    }
                    .contextMenu {
                        if let currentUser = Auth.auth().currentUser, !currentUser.isAnonymous {
                            Button {
                                friendManager.sendFriendRequest(toUsername: user.username) { result in
                                    switch result {
                                    case .success:
                                        print("✅ Request sent to \(user.username)")
                                    case .failure(let error):
                                        print("❌ \(error.localizedDescription)")
                                    }
                                }
                            } label: {
                                Label("Send Friend Request", systemImage: "person.badge.plus")
                            }
                        } else {
                            Button {
                                print("❌ You must be logged in to send a friend request.")
                            } label: {
                                Label("Login to Send Request", systemImage: "lock.fill")
                            }
                            .disabled(true)
                        }
                    }
                    
                }
            }
            .navigationTitle("Find Users")
            .onChange(of: searchText) { newValue in
                searchUsers(matching: newValue)
            }
        }
    }
    
    func searchUsers(matching text: String) {
        guard !text.isEmpty else {
            searchResults = []
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: text)
            .whereField("username", isLessThanOrEqualTo: text + "\u{f8ff}") // Firestore prefix query
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let docs = snapshot?.documents {
                    self.searchResults = docs.compactMap { doc in
                        let data = doc.data()
                        return AppUser(
                            id: doc.documentID,
                            username: data["username"] as? String ?? "",
                            profileName: data["profileName"] as? String ?? "",
                            level: data["level"] as? Int ?? 1,
                            xp: data["xp"] as? Int ?? 0
                        )
                    }
                }
            }
    }
}
