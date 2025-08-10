import SwiftUI
import FirebaseAuth

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var friendManager: FriendManager
    @EnvironmentObject var workoutStorage: WorkoutStorage
    
    @State private var showLogin = false
    @State private var showProfile = false
    @State private var showFriends = false
    @State private var showAvatar = false
    
    private var pendingCount: Int { friendManager.incomingRequests.count } 
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - User Info Section
                Button {
                    showProfile = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        // Profile Picture
                        if let urlString = profileManager.profile.profilePicURL,
                           let url = URL(string: urlString) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3) // Border
                                    .frame(width: 90, height: 90)
                                
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.4))
                                }
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3) // Border
                                    .frame(width: 90, height: 90)
                                
                                Circle()
                                    .fill(Color.gray.opacity(0.4))
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                        // Text Info and XP
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileManager.profile.profileName)
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            Text("@\(profileManager.profile.username)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Level \(profileManager.profile.level)")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.white)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [.green, .blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(
                                            width: geometry.size.width *
                                            CGFloat(profileManager.profile.xp) /
                                            CGFloat(max(profileManager.requiredXPForNextLevel, 1)),
                                            height: 8
                                        )
                                        .animation(.easeOut(duration: 0.4), value: profileManager.currentXPIntoLevel)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(profileManager.profile.xp) / \(profileManager.requiredXPForNextLevel) XP")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 50)
                
                Divider()
                    .background(Color.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                
                // FRIENDS button with badge
                HStack {
                    Spacer()
                    Button {
                        showFriends = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                            Text("Friends")
                            
                            if pendingCount > 0 {
                                Text("\(pendingCount)")
                                    .font(.caption2).bold()
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.red))
                                    .foregroundColor(.white)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: pendingCount) // nice pop
                    Spacer()
                }
                
                HStack {
                    Spacer()
                    Button {
                        showAvatar = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle")
                            Text("Avatar")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.spring(response: 0.3, dampingFraction: 0.8))
                    Spacer()
                }
                
                // MARK: - Auth Buttons
                if let user = Auth.auth().currentUser, !user.isAnonymous {
                    HStack {
                        Spacer()
                        Button(role: .destructive) {
                            do {
                                try Auth.auth().signOut()
                                DispatchQueue.main.async {
                                    profileManager.reset()
                                    achievementManager.reset()
                                    workoutStorage.reset()
                                }
                                Auth.auth().signInAnonymously { result, error in
                                    if let error = error {
                                        print("Anonymous sign-in failed: \(error)")
                                    }
                                }
                            } catch {
                                print("Error signing out: \(error)")
                            }
                        } label: {
                            Label("Logout", systemImage: "arrow.backward.circle")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                } else {
                    HStack {
                        Spacer()
                        Button {
                            showLogin = true
                        } label: {
                            Label("Sign Up / Login", systemImage: "person.badge.plus")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(width: 260)
            .background(Color("AppBackground"))
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                // Keep the badge live
                friendManager.fetchIncomingRequests()
            }
        }
        .fullScreenCover(isPresented: $showLogin) { LoginView{} }
        .sheet(isPresented: $showProfile) { UserProfileView() }
        .sheet(isPresented: $showFriends) { FriendsListView() }
        .fullScreenCover(isPresented: $showAvatar) { AvatarBuilderView() }
    }
}


