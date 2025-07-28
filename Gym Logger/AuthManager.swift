import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    @Published var user: User?

    init() {
        self.user = Auth.auth().currentUser

        Auth.auth().addStateDidChangeListener { _, newUser in
            DispatchQueue.main.async {
                self.user = newUser
            }
        }
    }

    var isAnonymous: Bool {
        user?.isAnonymous ?? true
    }

    var isLoggedIn: Bool {
        user != nil && !(user?.isAnonymous ?? true)
    }
}
