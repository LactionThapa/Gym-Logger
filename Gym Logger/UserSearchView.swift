import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserSearchView: View {
    @State private var searchText = ""
    @State private var allUsers: [AppUser] = []
    @State private var filtered: [AppUser] = []
    @State private var isLoading = false
    
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
                Color("AppBackground").ignoresSafeArea()

                VStack {
                    // If you prefer, replace this with .searchable on the NavigationStack
                    TextField("Search by username or name", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.asciiCapable)
                        .padding()

                    if isLoading {
                        ProgressView("Loading users…")
                            .padding(.top, 40)
                    } else {
                        // In your List:
                        List(currentData) { user in
                            row(for: user)                 // now returns a Button-based card
                                .listRowSeparator(.hidden) // optional, cleaner cards
                                .listRowBackground(Color.clear)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .refreshable { await loadAllUsers() } // pull-to-refresh if you want
                    }
                }
            }
            .navigationTitle("Find Users")
            .onAppear {
                Task { await loadAllUsers() }
                friendManager.fetchSentRequests { usernames in
                    sentRequests = usernames
                }
                friendManager.fetchFriendIDs { ids in
                    friendManager.fetchUsernames(for: ids) { userDict in
                        friendUsernames = Set(userDict.values)
                    }
                }
            }
            .onChange(of: searchText) { _ in
                Task { await runSearch() }
            }
            .alert("Friend Request", isPresented: $showConfirmation, presenting: pendingUser) { user in
                Button("Send") {
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
                Button("Cancel", role: .cancel) {}
            } message: { user in
                Text("Send a friend request to @\(user.username)?")
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Friend Request"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func runSearch() async {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else {
            // fall back to discoverable list already loaded
            await MainActor.run { filtered = [] }
            return
        }

        let db = Firestore.firestore()
        do {
            // prefix search (shows private users if their username matches)
            let snap = try await db.collection("users")
                .whereField("username", isEqualTo: q)
                .limit(to: 20)
                .getDocuments()

            let users = snap.documents.compactMap(mapDoc)
            await MainActor.run { self.filtered = users }
        } catch {
            // handle error if you want
        }
    }

    // MARK: - Data shown (filtered when typing)
    private var currentData: [AppUser] {
        searchText.isEmpty ? allUsers : filtered
    }

    // MARK: - UI pieces
    private func row(for user: AppUser) -> some View {
        @State var isPressed = false

        return Button {
            handleTap(on: user) // your tap action
        } label: {
            HStack(alignment: .center, spacing: 12) {
                // Avatar
                AsyncImage(url: URL(string: user.profilePicURL ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.fill")
                            .resizable().scaledToFit()
                            .padding(8)
                            .foregroundColor(.white)
                            .background(Color.gray)
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.profileName)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("@\(user.username)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("Level \(user.level) • \(user.xp) XP")
                        .font(.caption2)
                        .foregroundColor(.green)
                }

                Spacer()

                // Badges
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
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hex: "232F34"))
            .cornerRadius(16)
            .shadow(
                color: friendUsernames.contains(user.username)
                    ? .blue.opacity(0.3)
                    : .black.opacity(0.5),
                radius: 6, x: 0, y: 3
            )
            .scaleEffect(isPressed ? 0.97 : 1.0) // Push animation
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation { isPressed = false }
                }
        )
    }

    private func handleTap(on user: AppUser) {
        guard let currentUser = Auth.auth().currentUser, !currentUser.isAnonymous else {
            alertMessage = "Please log in to send friend requests."
            showAlert = true
            return
        }
        guard !sentRequests.contains(user.username),
              !friendUsernames.contains(user.username) else { return }

        pendingUser = user
        showConfirmation = true
    }

    // MARK: - Loading & Filtering
    private func applyFilter() {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else {
            filtered = []
            return
        }

        filtered = allUsers.filter { user in
            user.username.lowercased().contains(q) ||
            user.profileName.lowercased().contains(q)
        }
    }

    private func mapDoc(_ doc: DocumentSnapshot) -> AppUser? {
        let data = doc.data() ?? [:]
        return AppUser(
            id: doc.documentID,
            username: data["username"] as? String ?? "",
            profileName: data["profileName"] as? String ?? "",
            level: data["level"] as? Int ?? 1,
            xp: data["xp"] as? Int ?? 0,
            profilePicURL: data["profilePicURL"] as? String
        )
    }

    private func loadAllUsers() async {
        await MainActor.run { isLoading = true }
        let db = Firestore.firestore()

        do {
            // Only discoverable when browsing
            let snap = try await db.collection("users")
                .whereField("isDiscoverable", isEqualTo: true)
                .getDocuments()

            let users = snap.documents.compactMap(mapDoc)
            await MainActor.run {
                self.allUsers = users
                self.applyFilter()
                self.isLoading = false
            }
        } catch {
            await MainActor.run { self.isLoading = false }
        }
    }
}
