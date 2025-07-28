import SwiftUI
struct FriendRequestsView: View {
    @EnvironmentObject var friendManager: FriendManager
    @State private var usernames: [String: String] = [:]

    var body: some View {
        List {
            if friendManager.incomingRequests.isEmpty {
                Text("No incoming requests.")
                    .foregroundColor(.gray)
            } else {
                ForEach(friendManager.incomingRequests, id: \.self) { requesterID in
                    HStack {
                        Text("Request from: \(usernames[requesterID] ?? "Loading...")")
                            .fontWeight(.medium)
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
                    .onAppear {
                        if usernames[requesterID] == nil {
                            fetchUsername(for: requesterID)
                        }
                    }
                }
            }
        }
        .onAppear {
            friendManager.fetchIncomingRequests()
        }
        .navigationTitle("Friend Requests")
    }

    private func fetchUsername(for userID: String) {
        friendManager.getUsername(forUserID: userID) { username in
            DispatchQueue.main.async {
                usernames[userID] = username ?? "Unknown1"
            }
        }
    }
}

