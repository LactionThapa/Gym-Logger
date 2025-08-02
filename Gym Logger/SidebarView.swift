import SwiftUI
import FirebaseAuth

struct SidebarView: View {
    @Binding var isShowing: Bool
    @EnvironmentObject var profileManager: UserProfileManager

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Profile Section
            HStack {
                if let urlString = profileManager.profile.profilePicURL,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                }

                VStack(alignment: .leading) {
                    Text(profileManager.profile.profileName)
                        .bold()
                    Text("@\(profileManager.profile.username)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.top, 40)

            Divider()

            // Menu Items
            NavigationLink(destination: UserProfileView()) {
                Label("Profile", systemImage: "person")
            }

            Button(action: logout) {
                Label("Logout", systemImage: "arrowshape.turn.up.left")
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .edgesIgnoringSafeArea(.all)
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            // Redirect to login screen if needed
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
