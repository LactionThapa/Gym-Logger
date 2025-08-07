import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct FriendLeaderboardView: View {
    @EnvironmentObject var friendManager: FriendManager
    @State private var leaderboard: [AppUser] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()

                VStack {
                    if isLoading {
                        ProgressView("Loading Leaderboard...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if leaderboard.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No friends found.")
                                .font(.headline)
                            Text("Add friends to see how you rank!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(leaderboard.enumerated().map { $0 }, id: \.element.id) { index, user in
                                    LeaderboardRowView(
                                        user: user,
                                        rank: index + 1,
                                        isCurrentUser: user.id == Auth.auth().currentUser?.uid
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Leaderboard")
                        .font(.title2.bold()) // ✅ Bigger navigation title
                        .foregroundColor(.white)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                fetchLeaderboard()
            }
        }
    }

    func fetchLeaderboard() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        isLoading = true

        friendManager.fetchFriendIDs { friendIDs in
            var idsToQuery = friendIDs
            idsToQuery.append(uid)

            guard !idsToQuery.isEmpty else {
                leaderboard = []
                isLoading = false
                return
            }

            db.collection("users")
                .whereField(FieldPath.documentID(), in: idsToQuery)
                .getDocuments { snapshot, error in
                    isLoading = false

                    guard let docs = snapshot?.documents, error == nil else {
                        print("Error fetching leaderboard: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }

                    leaderboard = docs.compactMap { doc in
                        let data = doc.data()
                        return AppUser(
                            id: doc.documentID,
                            username: data["username"] as? String ?? "",
                            profileName: data["profileName"] as? String ?? "",
                            level: data["level"] as? Int ?? 1,
                            xp: data["xp"] as? Int ?? 0,
                            profilePicURL: data["profilePicURL"] as? String // ✅ new field
                        )
                    }
                    .sorted {
                        if $0.level == $1.level {
                            return $0.xp > $1.xp
                        } else {
                            return $0.level > $1.level
                        }
                    }
                }
        }
    }
}
struct LeaderboardRowView: View {
    let user: AppUser
    let rank: Int
    let isCurrentUser: Bool

    @State private var animateGlow = false
    @State private var isVisible = false


    var body: some View {
        let glowColor: Color = {
            switch rank {
            case 1: return .yellow
            case 2: return .gray
            case 3: return .orange
            default: return .clear
            }
        }()

        HStack(spacing: 12) {
            rankIcon(for: rank)
                .frame(width: 30)

            AsyncImage(url: URL(string: user.profilePicURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(borderColor(for: rank), lineWidth: 2)
                        )
                        .shadow(
                            color: borderColor(for: rank).opacity(animateGlow ? 0.8 : 0.3),
                            radius: animateGlow ? 10 : 4
                        )
                default:
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(borderColor(for: rank), lineWidth: 2)
                        )
                        .shadow(
                            color: borderColor(for: rank).opacity(animateGlow ? 0.8 : 0.3),
                            radius: animateGlow ? 10 : 4
                        )
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(user.profileName)
                    .fontWeight(isCurrentUser ? .bold : .regular)
                    .foregroundColor(.white)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Lv \(user.level)")
                    .foregroundColor(.white)
                Text("\(user.xp) XP")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(hex: "232F34"))
        .cornerRadius(10)
        .shadow(color: glowColor.opacity(animateGlow ? 0.6 : 0.2), radius: animateGlow ? 10 : 4)
        .onAppear {
            isVisible = true
            if rank <= 3 {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGlow = true
                }
            }
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(Double(rank) * 0.05), value: isVisible)
    }

    @ViewBuilder
    func rankIcon(for rank: Int) -> some View {
        switch rank {
        case 1:
            Image(systemName: "crown.fill")
                .foregroundColor(.yellow)
        case 2:
            Text("🥈")
        case 3:
            Text("🥉")
        default:
            Text("#\(rank)")
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
    func borderColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.2)
        }
    }
}


