import SwiftUI
import FirebaseAuth

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var profileManager: UserProfileManager
    @State private var showLogin = false
    @State private var showProfile = false
    @State private var showFriends = false
    
    var body: some View {
        NavigationStack{
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - User Info Section
                Button {
                    showProfile = true
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        // Profile Picture
                        if let urlString = profileManager.profile.profilePicURL,
                           let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.4))
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.4))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // Text Info and XP
                        VStack(alignment: .leading, spacing: 4) {
                            Text(profileManager.profile.profileName ?? "Your Name")
                                .font(.headline)
                            
                            Text("@\(profileManager.profile.username ?? "username")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Level \(profileManager.profile.level)")
                                .font(.caption)
                                .bold()
                            
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
                                            CGFloat(profileManager.currentXPIntoLevel) /
                                            CGFloat(max(profileManager.requiredXPForNextLevel, 1)),
                                            height: 8
                                        )
                                        .animation(.easeOut(duration: 0.4), value: profileManager.currentXPIntoLevel)
                                }
                            }
                            .frame(height: 8)
                            
                            Text("\(profileManager.currentXPIntoLevel) / \(profileManager.requiredXPForNextLevel) XP")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle()) // Prevents button appearance
                .padding(.top, 50)
                
                Divider().padding(.vertical, 10)
                
                Button {
                    showFriends = true
                } label: {
                    Label("Friends", systemImage: "person.2.fill")
                }
                
                if let user = Auth.auth().currentUser, !user.isAnonymous {
                    Button(role: .destructive) {
                        do {
                            try Auth.auth().signOut()
                            DispatchQueue.main.async {
                                profileManager.reset()
                                achievementManager.reset()
                            }
                            
                            // Automatically sign in anonymously again
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
                    }
                } else {
                    Button {
                        showLogin = true
                    } label: {
                        Label("Sign Up / Login", systemImage: "person.badge.plus")
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(width: 260)
            .background(.ultraThinMaterial)
            .edgesIgnoringSafeArea(.all)
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView{
            }
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView()
        }
        .sheet(isPresented: $showFriends) {
            FriendsListView()
        }
    }
}
