import SwiftUI
import FirebaseAuth

struct UserProfileView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var workoutTemplateStorage: WorkoutTemplateStorage
    @EnvironmentObject var profileManager: UserProfileManager
    
    @State private var showingImagePicker = false
    @State private var profileImage: Image? = nil
    @State private var inputImage: UIImage?
    
    @State private var unlockedAchievement: Achievement? = nil
    @State private var showPopup: Bool = false
    
    @State private var showingLogin = false
    @State private var alreadySynced = false
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        if authManager.isAnonymous {
                            Button("Sync My Data") {
                                showingLogin = true
                            }
                            .sheet(isPresented: $showingLogin) {
                                LoginView {
                                    Task {
                                        let profileData = try? await profileManager.getCurrentProfileData()
                                        let workoutsData = try? await workoutStorage.getAllWorkouts()
                                        
                                        try await Task.sleep(nanoseconds: 1_000_000_000)
                                        
                                        if let profileData = profileData {
                                            try? await profileManager.setProfileData(profileData)
                                        }
                                        if let workoutsData = workoutsData {
                                            try? await workoutStorage.saveWorkouts(workoutsData)
                                        }
                                        
                                        profileManager.fetchUserProfile()
                                        workoutStorage.load()
                                        workoutTemplateStorage.fetchTemplates()
                                    }
                                }
                            }
                        }
                        
                        if let user = Auth.auth().currentUser {
                            Text(user.isAnonymous ? "Not synced" : "Synced")
                                .font(.caption)
                                .foregroundColor(user.isAnonymous ? .red : .green)
                        }
                        
                        if authManager.isLoggedIn {
                            Text("Logged in as \(profileManager.profile.username.isEmpty ? "Unnamed" : profileManager.profile.username)")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Button(role: .destructive) {
                                do {
                                    try Auth.auth().signOut()
                                    DispatchQueue.main.async {
                                        profileManager.reset()
                                        achievementManager.reset()
                                    }
                                    // Optionally sign in anonymously again to keep app usable
                                    Auth.auth().signInAnonymously { result, error in
                                        if let error = error {
                                            print("Anonymous sign-in failed: \(error)")
                                        }
                                    }
                                } catch {
                                    print("Error signing out: \(error)")
                                }
                            } label: {
                                Text("Log Out")
                                    .foregroundColor(.red)
                            }
                        }
                        profilePicture
                        
                        TextField("Enter Name", text: $profileManager.profile.profileName)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        xpSection
                        
                        Divider().padding(.vertical)
                        
                        personalBests
                        
                        Divider().padding(.vertical)
                        
                        achievementsSection
                    }
                    .padding()
                }
                
                // 🏆 Popup when achievement is unlocked
                if let achievement = unlockedAchievement, showPopup {
                    AchievementUnlockedView(achievement: achievement, isVisible: $showPopup)
                        .zIndex(1)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) {
                loadImage()
            }
            .onChange(of: profileManager.profile.profileName) { newValue in
                profileManager.updateName(newValue)
            }
            .onAppear {
                achievementManager.evaluateAchievements(using: workoutStorage.history) { newAchievement in
                    unlockedAchievement = newAchievement
                    withAnimation {
                        showPopup = true
                    }
                    profileManager.unlockAchievement(newAchievement.id)
                }
            }
            
        }
    }
    
    // MARK: - Profile Picture
    private var profilePicture: some View {
        ZStack {
            if let profileImage = profileImage {
                profileImage
                    .resizable()
                    .scaledToFill()
            } else if let urlString = profileManager.profile.profilePicURL,
                      let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        Image(systemName: "person.crop.circle.fill")
                            .resizable().scaledToFit()
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
        .onTapGesture {
            showingImagePicker = true
        }
    }
    
    
    // MARK: - XP Display
    private var xpSection: some View {
        VStack(spacing: 6) {
            Text("Level \(profileManager.profile.level)")
                .font(.headline)
            
            ProgressView(value: Double(profileManager.currentXPIntoLevel),
                         total: Double(profileManager.requiredXPForNextLevel))
            .accentColor(.green)
            .padding(.horizontal)
            
            Text("\(profileManager.currentXPIntoLevel) / \(profileManager.requiredXPForNextLevel) XP")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Personal Bests
    private var personalBests: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏋️‍♂️ Personal Bests")
                .font(.headline)
            
            ForEach(topWeights(), id: \.0) { name, weight in
                HStack {
                    Text(name)
                    Spacer()
                    Text("\(weight, specifier: "%.1f") kg")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    // MARK: - Achievements
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🏅 Achievements")
                .font(.headline)
            
            ForEach(achievementManager.achievements) { badge in
                HStack {
                    Image(systemName: badge.imageName)
                        .foregroundColor(badge.earned ? .yellow : .gray)
                        .frame(width: 30)
                    VStack(alignment: .leading) {
                        Text(badge.title)
                            .fontWeight(.semibold)
                        Text(badge.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if badge.earned {
                        Text("✓")
                            .foregroundColor(.green)
                    }else{
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                    }
                }
                .opacity(badge.earned ? 1.0 : 0.5)
                .padding(.horizontal)
            }
        }
        .padding()
    }
    
    // MARK: - Helpers
    private func topWeights() -> [(String, Double)] {
        var maxMap: [String: Double] = [:]
        for workout in workoutStorage.history {
            for exercise in workout.exercises {
                let maxWeight = exercise.weight
                if let current = maxMap[exercise.name] {
                    maxMap[exercise.name] = max(current, maxWeight)
                } else {
                    maxMap[exercise.name] = maxWeight
                }
            }
        }
        return maxMap.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
        profileManager.uploadProfileImage(inputImage) { url in
            // Already updates profileManager.profile.profilePicURL
        }
        saveProfileImage(inputImage)
    }
    
    private func saveProfileImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            let url = getDocumentsDirectory().appendingPathComponent("profile.jpg")
            try? data.write(to: url)
        }
    }
    
    private func loadSavedProfileImage() {
        let url = getDocumentsDirectory().appendingPathComponent("profile.jpg")
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            profileImage = Image(uiImage: uiImage)
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

struct AchievementUnlockedView: View {
    let achievement: Achievement
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            VStack(spacing: 12) {
                Image(systemName: achievement.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.yellow)
                
                Text("Achievement Unlocked!")
                    .font(.headline)
                    .bold()
                
                Text(achievement.title)
                    .font(.subheadline)
                    .padding(.bottom, 10)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 10)
            .transition(.scale)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
        }
    }
}
