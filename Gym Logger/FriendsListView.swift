struct FriendsListView: View {
    @EnvironmentObject var friendManager: FriendManager
    @State private var newFriendID = ""
    @State private var newFriendName = ""

    var body: some View {
        NavigationStack {
            List {
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
                        Button(role: .destructive) {
                            friendManager.removeFriend(friendID: friend.id)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }

            Section(header: Text("Add Friend")) {
                TextField("Friend ID", text: $newFriendID)
                TextField("Friend Name", text: $newFriendName)

                Button("Add Friend") {
                    friendManager.addFriend(byFriendID: newFriendID, name: newFriendName)
                    newFriendID = ""
                    newFriendName = ""
                }
            }
            .padding()
            .navigationTitle("My Friends")
        }
        .onAppear {
            friendManager.fetchFriends()
        }
    }
}
