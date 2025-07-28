struct FriendRequestsView: View {
    @EnvironmentObject var friendManager: FriendManager
    
    var body: some View {
        List {
            ForEach(friendManager.incomingRequests, id: \.self) { requesterID in
                HStack {
                    Text("Request from: \(requesterID)") // Replace with username fetch
                    Spacer()
                    Button("Accept") {
                        friendManager.acceptFriendRequest(fromUserID: requesterID)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reject") {
                        friendManager.rejectFriendRequest(fromUserID: requesterID)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .onAppear {
            friendManager.fetchIncomingRequests()
        }
        .navigationTitle("Friend Requests")
    }
}