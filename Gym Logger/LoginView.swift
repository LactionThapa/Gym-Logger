import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Sync Your Progress")
                    .font(.title2)
                    .bold()

                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if isLoading {
                    ProgressView()
                } else {
                    Button("Link Account & Sync") {
                        linkAccount()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button("Cancel") {
                    dismiss()
                }
                .padding(.top, 8)
            }
            .padding()
            .navigationTitle("Login or Sign Up")
        }
    }

    private func linkAccount() {
        isLoading = true
        errorMessage = ""

        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        if let user = Auth.auth().currentUser {
            user.link(with: credential) { result, error in
                isLoading = false

                if let error = error as NSError? {
                    if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                        // If the email is already in use, sign in instead and migrate data
                        signInInstead()
                    } else {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    dismiss()
                }
            }
        } else {
            errorMessage = "No user session found."
            isLoading = false
        }
    }

    private func signInInstead() {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        Auth.auth().signIn(with: credential) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                dismiss()
            }
        }
    }
}
