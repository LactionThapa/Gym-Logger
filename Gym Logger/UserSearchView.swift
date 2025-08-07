import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [AppUser] = []
    @EnvironmentObject var friendManager: FriendManager
    @State private var sentRequests: Set<String> = []
    @State private var friendUsernames: Set<String> = []
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showConfirmation = false
    @State private var pendingUser: AppUser? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()
                
                VStack {
                    TextField("Search by username", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                    
                    List(searchResults) { user in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(user.profileName)
                                Text("@\(user.username)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Lv \(user.level)")
                                Text("\(user.xp) XP")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                if friendUsernames.contains(user.username) {
                                    Label("Friends", systemImage: "person.fill.checkmark")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                } else if sentRequests.contains(user.username) {
                                    Label("Requested", systemImage: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard let currentUser = Auth.auth().currentUser, !currentUser.isAnonymous else {
                                alertMessage = "Please log in to send friend requests."
                                showAlert = true
                                return
                            }

                            guard !sentRequests.contains(user.username),
                                  !friendUsernames.contains(user.username) else {
                                return
                            }

                            pendingUser = user
                            alertMessage = "Send friend request to @\(user.username)?"
                            showConfirmation = true
                        }
                    }
                    .scrollContentBackground(.hidden) // ✅ Remove default list background
                    .background(Color.clear)
                    
                    .alert("Friend Request", isPresented: $showConfirmation, presenting: pendingUser) { user in
                        Button("Send", role: .none) {
                            friendManager.sendFriendRequest(toUsername: user.username) { result in
                                switch result {
                                case .success:
                                    sentRequests.insert(user.username)
                                    alertMessage = "Friend request sent to @\(user.username)"
                                case .failure(let error):
                                    alertMessage = "Error: \(error.localizedDescription)"
                                }
                                showAlert = true
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: { user in
                        Text("Would you like to send a friend request to @\(user.username)?")
                    }
                    
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Friend Request"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .navigationTitle("Find Users")
            .onChange(of: searchText) { newValue in
                searchUsers(matching: newValue)
            }
            .onAppear {
                friendManager.fetchSentRequests { usernames in
                    sentRequests = usernames
                }
                friendManager.fetchFriendIDs { ids in
                    friendManager.fetchUsernames(for: ids) { userDict in
                        friendUsernames = Set(userDict.values)
                    }
                }
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
            .whereField("username", isLessThanOrEqualTo: text + "\u{f8ff}")
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
