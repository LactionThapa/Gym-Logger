import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var friendManager: FriendManager
    @State private var newFriendName = ""
    @State private var statusMessage = ""
    @State private var isLoading = false
    @State private var showUserSearch = false
    
    var body: some View {
        let pendingRequestCount = friendManager.incomingRequests.count

        NavigationStack {
            List {
                // 🔗 Friend Requests Navigation
                NavigationLink {
                    FriendRequestsView()
                } label: {
                    HStack {
                        Text("View Friend Requests")
                        Spacer()
                        if friendManager.incomingRequests.count > 0 {
                            Text("\(friendManager.incomingRequests.count)")
                                .font(.caption2)
                                .padding(6)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                }

                // 👫 Existing Friends
                Section(header: Text("My Friends")) {
                    ForEach(friendManager.friends) { friend in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(friend.name)
                                    .font(.headline)
                                Text("Friends since \(friend.since.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                friendManager.removeFriend(friendID: friend.id)
                            } label: {
                                Label("Remove Friend", systemImage: "trash")
                            }
                        }
                    }
                }
                
                // ➕ Add Friend
                Section(header: Text("Add Friend")) {
                    Button("Search Users") {
                        showUserSearch = true
                    }
                }
                .sheet(isPresented: $showUserSearch) {
                    UserSearchView()
                        .environmentObject(friendManager)
                }
            }
            .navigationTitle("My Friends")
            .onAppear {
                friendManager.fetchFriends()
                friendManager.fetchIncomingRequests()
            }
        }
    }
    private func sendFriendRequest() {
        isLoading = true
        statusMessage = ""
        
        friendManager.sendFriendRequest(toUsername: newFriendName) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    statusMessage = "✅ Friend request sent!"
                    newFriendName = ""
                case .failure(let error):
                    statusMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }
}
