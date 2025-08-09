import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @EnvironmentObject var profileManager: UserProfileManager
    @EnvironmentObject var achievementManager: AchievementManager
    
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isLoginMode = true
    var onLoginSuccess: (() -> Void)? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AppBackground")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text(isLoginMode ? "Log In to Sync" : "Create Account to Sync")
                        .font(.title2)
                        .foregroundColor(.white)
                        .bold()
                    
                    if !isLoginMode {
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    
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
                        Button(action: handleAction) {
                            Text(isLoginMode ? "Log In & Sync" : "Sign Up & Sync")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex:"F9AA33"))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    
                    Button(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Log In") {
                        isLoginMode.toggle()
                        errorMessage = ""
                    }
                    .font(.footnote)
                    .foregroundColor(Color(hex: "F9AA33"))
                    .padding(.top, 8)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "F9AA33"))
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Account Sync")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    
    private func handleAction() {
        isLoading = true
        errorMessage = ""
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        
        guard let anonUser = Auth.auth().currentUser else {
            errorMessage = "No user session found."
            isLoading = false
            return
        }
        
        if !isLoginMode && !isValidSignupInput() {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let anonUID = anonUser.uid
        
        Task {
            do {
                let anonProfileDoc = try await db.collection("users").document(anonUID).getDocument()
                let anonProfileData = anonProfileDoc.data()
                
                let anonWorkouts = try await db.collection("users").document(anonUID).collection("workouts").getDocuments()
                let anonTemplates = try await db.collection("users").document(anonUID).collection("templates").getDocuments()
                
                if isLoginMode {
                    // Log in
                    Auth.auth().signIn(with: credential) { result, error in
                        isLoading = false
                        if let error = error {
                            errorMessage = error.localizedDescription
                            return
                        }
                        
                        guard let newUID = result?.user.uid else { return }
                        
                        // Migrate data
                        migrateData(to: newUID, profile: anonProfileData, workouts: anonWorkouts, templates: anonTemplates)
                        profileManager.fetchUserProfile()
                        achievementManager.loadAchievements()
                        
                    }
                } else {
                    // SIGNUP
                    let usernameRef = db.collection("usernames").document(username)
                    
                    let usernameSnapshot = try await usernameRef.getDocument()
                    if usernameSnapshot.exists {
                        errorMessage = "Username is already taken."
                        isLoading = false
                        return
                    }
                    
                    let emailMethods = try await Auth.auth().fetchSignInMethods(forEmail: email)
                    if !emailMethods.isEmpty {
                        errorMessage = "Email is already registered."
                        isLoading = false
                        return
                    }
                    
                    // Safe to proceed: Link the anonymous user
                    anonUser.link(with: credential) { result, error in
                        if let error = error as NSError? {
                            isLoading = false
                            if error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                                signInInstead(with: credential)
                            } else {
                                errorMessage = error.localizedDescription
                            }
                            return
                        }
                        
                        guard let newUID = result?.user.uid else {
                            errorMessage = "User ID not available."
                            isLoading = false
                            return
                        }
                        
                        Task {
                            do {
                                try await usernameRef.setData(["userId": newUID])
                                try await db.collection("users").document(newUID).setData(["username": username], merge: true)
                                
                                DispatchQueue.main.async {
                                    profileManager.profile.username = username
                                    profileManager.save()
                                    profileManager.fetchUserProfile()
                                }
                                
                                migrateData(to: newUID, profile: anonProfileData, workouts: anonWorkouts, templates: anonTemplates)
                                isLoading = false
                                onLoginSuccess?()
                                dismiss()
                            } catch {
                                errorMessage = "Failed to save user data: \(error.localizedDescription)"
                                isLoading = false
                            }
                        }
                    }
                }
            } catch {
                errorMessage = "Unexpected error: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    private func signInInstead(with credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { result, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                dismiss()
            }
        }
    }
    
    private func migrateData(to newUID: String, profile: [String: Any]?, workouts: QuerySnapshot, templates: QuerySnapshot) {
        let db = Firestore.firestore()
        let newUserRef = db.collection("users").document(newUID)
        
        if let profile = profile {
            newUserRef.setData(profile, merge: true)
        }
        
        for doc in workouts.documents {
            newUserRef.collection("workouts").document(doc.documentID).setData(doc.data())
        }
        
        for doc in templates.documents {
            newUserRef.collection("templates").document(doc.documentID).setData(doc.data())
        }
        
        onLoginSuccess?()
        dismiss()
    }
    private func isValidSignupInput() -> Bool {
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Username is required."
            return false
        }
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty || !email.contains("@") {
            errorMessage = "Enter a valid email address."
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        
        return true
    }
    
}
