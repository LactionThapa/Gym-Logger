import SwiftUI

enum FriendsTab: String, CaseIterable {
    case friends = "Friends"
    case incoming = "Requests"
    case sent = "Sent"
}

struct FriendsListView: View {
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var selectedTab: FriendsTab = .friends
    @State private var showUserSearch = false
    @State private var usernames: [String: String] = [:]
    @State private var sentRequests: Set<String> = []
    @State private var friendUsers: [String: AppUser] = [:]
    @State private var incomingUsers: [String: AppUser] = [:]
    @State private var sentUserIDs: [String] = []
    @State private var sentUsers: [String: AppUser] = [:] // keyed by userID
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    FriendCountHeader(
                        count: friendManager.friends.count,
                        limit: 99
                    ) {
                        showUserSearch = true   // open your user search to add friends
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Tab Selector
                    Picker("Tab", selection: $selectedTab) {
                        ForEach(FriendsTab.allCases, id: \.self) {
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    TabView(selection: $selectedTab) {
                        // Friends Tab
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if(friendManager.friends.isEmpty){
                                    Text("No Friends")
                                        .foregroundColor(.gray)
                                }else{
                                    ForEach(friendManager.friends) { friend in
                                        if let user = friendUsers[friend.id] {
                                            FriendCardView(
                                                user: user,
                                                color: .green,
                                                removeAction: {
                                                    friendManager.removeFriend(friendID: friend.id)
                                                }
                                            )
                                        }
                                    }
                                }
                                
                            }
                            .padding(.horizontal)
                        }
                        .tag(FriendsTab.friends)
                        // Incoming Requests Tab
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if friendManager.incomingRequests.isEmpty {
                                    Text("No incoming requests.")
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(friendManager.incomingRequests, id: \.self) { requesterID in
                                        IncomingRequestCard(
                                            user: incomingUsers[requesterID],
                                            onAccept: {
                                                friendManager.acceptFriendRequest(fromUserID: requesterID)
                                            },
                                            onReject: {
                                                friendManager.rejectFriendRequest(fromUserID: requesterID)
                                            }
                                        )
                                        .task {
                                            // Fetch once per requester
                                            if incomingUsers[requesterID] == nil {
                                                friendManager.getUserProfile(forUserID: requesterID) { user in
                                                    if let user { DispatchQueue.main.async { incomingUsers[requesterID] = user } }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .tag(FriendsTab.incoming)
                        // Sent Requests Tab
                        // Sent Requests Tab
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if sentUserIDs.isEmpty {
                                    Text("No sent requests.")
                                        .foregroundColor(.gray)
                                } else {
                                    ForEach(sentUserIDs, id: \.self) { userID in
                                        SentRequestCard(user: sentUsers[userID])
                                            .task {
                                                // Safety: if user not yet loaded, fetch it
                                                if sentUsers[userID] == nil {
                                                    friendManager.getUserProfile(forUserID: userID) { user in
                                                        if let user {
                                                            DispatchQueue.main.async {
                                                                sentUsers[userID] = user
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .tag(FriendsTab.sent)
                        
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Friends")
                        .font(.system(size: 28, weight: .bold)) // Bigger custom font
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Image(systemName: profileManager.profile.isDiscoverable ? "eye" : "eye.slash")
                            .foregroundColor(Color(hex: "F9AA33"))
                        Toggle("Discoverable", isOn: Binding(
                            get: { profileManager.profile.isDiscoverable },
                            set: { profileManager.setDiscoverable($0) }
                        ))
                        .labelsHidden()
                    }
                    .padding(8)
                    .background(
                        Capsule().fill(Color.white.opacity(0.08))
                    )
                }
            }
            .onAppear {
                friendManager.fetchFriends()
                friendManager.fetchIncomingRequests()
                friendManager.fetchSentRequests { usernames in
                    // usernames is a Set<String> of usernames
                    // Resolve each to userID, then fetch profile
                    for username in usernames {
                        friendManager.lookupUserID(forUsername: username) { result in
                            switch result {
                            case .success(let userID):
                                if !sentUserIDs.contains(userID) {
                                    sentUserIDs.append(userID)
                                }
                                if sentUsers[userID] == nil {
                                    friendManager.getUserProfile(forUserID: userID) { user in
                                        if let user {
                                            DispatchQueue.main.async {
                                                sentUsers[userID] = user
                                            }
                                        }
                                    }
                                }
                            case .failure:
                                break
                            }
                        }
                    }
                }
                
                // Delay to ensure friends list is populated before fetching profiles
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    for friend in friendManager.friends {
                        if friendUsers[friend.id] == nil {
                            friendManager.getUserProfile(forUserID: friend.id) { user in
                                if let user = user {
                                    DispatchQueue.main.async {
                                        friendUsers[friend.id] = user
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showUserSearch) {
                UserSearchView()
                    .environmentObject(friendManager)
            }
            .overlay(alignment: .bottom) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(18)
                        .background(
                            Circle()
                                .fill(Color(hex: "F9AA33")) // nice frosted look; switch to Color.white.opacity(0.12) if you prefer
                                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        )
                        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 6)
                }
                // lift it above the Home indicator / sheet grabber
                .padding(.bottom, 24)
                .accessibilityLabel("Close")
            }
            
        }
    }
    private func fetchUsername(for userID: String) {
        print("➡️ fetchUsername called for: \(userID)")
        
        friendManager.getUsername(forUserID: userID) { username in
            DispatchQueue.main.async {
                if let username = username {
                    print("✅ Username fetched for \(userID): \(username)")
                    usernames[userID] = username
                } else {
                    print("❌ Failed to fetch username for \(userID)")
                    usernames[userID] = "Unknown1"
                }
            }
        }
    }
    
    private func fetchUserInfo(for userID: String) {
        friendManager.getUserProfile(forUserID: userID) { user in
            if let user = user {
                DispatchQueue.main.async {
                    friendUsers[userID] = user
                }
            }
        }
    }
}
struct FriendCardView: View {
    let user: AppUser
    var color: Color
    var acceptAction: (() -> Void)? = nil
    var rejectAction: (() -> Void)? = nil
    var removeAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .center) {
            // Profile Picture
            AsyncImage(url: URL(string: user.profilePicURL ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.profileName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Level \(user.level)")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                
                if let remove = removeAction {
                    Button(action: remove) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Circle().fill(Color.red.opacity(0.8)))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "232F34"))
        .cornerRadius(16)
        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}
struct IncomingRequestCard: View {
    let user: AppUser?
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let urlStr = user?.profilePicURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Circle().fill(Color.gray.opacity(0.4))
                            .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle().fill(Color.gray.opacity(0.4))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user?.profileName ?? "Loading…")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let username = user?.username {
                    Text("@\(username)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Text("@…")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
                
                if let level = user?.level {
                    Text("Level \(level)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 10) {
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.green))
                }
                Button(action: onReject) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.red))
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "232F34"))
        .cornerRadius(16)
        .shadow(color: .red.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}
struct SentRequestCard: View {
    let user: AppUser?
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let urlStr = user?.profilePicURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Circle().fill(Color.gray.opacity(0.4))
                            .overlay(Image(systemName: "person.fill").foregroundColor(.white))
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle().fill(Color.gray.opacity(0.4))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.white))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user?.profileName ?? "Loading…")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("@\(user?.username ?? "…")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if let level = user?.level {
                    Text("Level \(level)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Pending badge bottom-right
            VStack {
                Spacer()
                Text("Pending")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: "232F34"))
        .cornerRadius(16)
        .shadow(color: .yellow.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

struct FriendCountHeader: View {
    let count: Int
    let limit: Int
    var onAddTapped: () -> Void
    
    private let cardBG = Color(red: 35/255, green: 47/255, blue: 52/255) // #232F34
    
    var body: some View {
        ZStack(alignment: .top) {
            // Card
            HStack(spacing: 12) {
                Text("Number of friends")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Count chip
                Text("\(count)/\(limit)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
                    )
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 28)
                    .cornerRadius(1)
                
                // Add button
                Button(action: onAddTapped) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(8)
                        .background(
                            Circle().fill(Color.white.opacity(0.06))
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: "4A6572"))
            )
            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
            
            // Thin gradient bar on top edge
            LinearGradient(
                colors: [.cyan, .green, .yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 2)
            .offset(y: -2) // sit right on the top edge
        }
    }
}

