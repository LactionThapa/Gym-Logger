import SwiftUI
import FirebaseAuth
import FirebaseFirestore
struct FriendLeaderboardView: View {
    @EnvironmentObject var friendManager: FriendManager
    @State private var leaderboard: [AppUser] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(leaderboard.enumerated().map { $0 }, id: \.element.id) { index, user in
                    HStack {
                        Text("#\(index + 1)")
                            .bold()
                            .frame(width: 30)
                        VStack(alignment: .leading) {
                            Text(user.profileName)
                                .fontWeight(user.id == Auth.auth().currentUser?.uid ? .bold : .regular)
                            Text("@\(user.username)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("Lv \(user.level)")
                        Text("\(user.xp) XP").font(.caption).foregroundColor(.green)
                    }
                    .background(user.id == Auth.auth().currentUser?.uid ? Color.blue.opacity(0.05) : Color.clear)
                }
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                fetchLeaderboard()
            }
        }
    }

    func fetchLeaderboard() {
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        friendManager.fetchFriendIDs { friendIDs in
            var idsToQuery = friendIDs
            idsToQuery.append(uid) // ✅ Include current user ID

            db.collection("users")
                .whereField(FieldPath.documentID(), in: idsToQuery)
                .getDocuments { snapshot, error in
                    if let docs = snapshot?.documents {
                        leaderboard = docs.compactMap { doc in
                            let data = doc.data()
                            return AppUser(
                                id: doc.documentID,
                                username: data["username"] as? String ?? "",
                                profileName: data["profileName"] as? String ?? "",
                                level: data["level"] as? Int ?? 1,
                                xp: data["xp"] as? Int ?? 0
                            )
                        }
                        .sorted(by: { $0.xp > $1.xp })
                    }
                }
        }
    }

}
