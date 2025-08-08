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
                Color("AppBackground") // background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profilePicture
                        
                        xpSection
                        
                        TextField("Enter Name", text: $profileManager.profile.profileName)
                            .font(.title2)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if !profileManager.profile.username.isEmpty {
                            Text("@\(profileManager.profile.username)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.5))
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                        
                        personalBests

                        Divider()
                            .background(Color.white.opacity(0.5))
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
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
        // compute progress safely
        let current = Double(profileManager.currentXPIntoLevel)
        let required = max(Double(profileManager.requiredXPForNextLevel), 1)
        let pct = current / required

        return ZStack {
            // XP ring behind the avatar
            XPRing(targetProgress: pct)
                .frame(width: 140, height: 140)   // ring size

            // Avatar
            ZStack {
                if let profileImage = profileImage {
                    profileImage.resizable().scaledToFill()
                } else if let urlString = profileManager.profile.profilePicURL,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image): image.resizable().scaledToFill()
                        case .empty: ProgressView()
                        default:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable().scaledToFit()
                                .foregroundColor(.gray)
                        }
                    }
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable().scaledToFit()
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 120, height: 120)        // avatar size (a bit smaller than ring)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 2) // subtle inner border
            )
        }
        .onTapGesture { showingImagePicker = true }
    }
    // MARK: - XP Display
    private var xpSection: some View {
        VStack(spacing: 6) {
            Text("Lv. \(profileManager.profile.level)")
                .font(.system(size: 20, weight: .bold))
                .bold()
            Text("\(profileManager.currentXPIntoLevel) / \(profileManager.requiredXPForNextLevel) XP")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Personal Bests
    // MARK: - Personal Bests
    private var personalBests: some View {
        VStack(spacing: 12) {
            // Centered title
            Text("🏋️‍♂️ Personal Bests")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(topWeights(), id: \.0) { name, weight in
                    HStack {
                        Text(name)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(weight, specifier: "%.1f") kg")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(hex: "#4A6572"))
        .cornerRadius(12)
    }

    // MARK: - Achievements
    // MARK: - Achievements (Grid)
    private var achievementsSection: some View {
        VStack(spacing: 12) {
            Text("🏅 Achievements")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            AchievementGrid(badges: achievementManager.achievements)
        }
        .padding()
        .background(Color(hex: "#4A6572"))
        .cornerRadius(12)
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
struct XPRing: View {
    let targetProgress: Double    // the final value (0.0 ... 1.0)
    let lineWidth: CGFloat = 8
    @State private var displayedProgress: Double = 0 // for animation

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: lineWidth)

            // Progress
            Circle()
                .trim(from: 0, to: displayedProgress.clamped(to: 0...1))
                .stroke(
                    AngularGradient(
                        colors: [.green, .blue],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90)) // start at top
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                displayedProgress = targetProgress
            }
        }
        .onChange(of: targetProgress) { newValue in
            withAnimation(.easeOut(duration: 1.0)) {
                displayedProgress = newValue
            }
        }
    }
}


private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Grid
struct AchievementGrid: View {
    let badges: [Achievement]
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(badges) { badge in
                AchievementCard(badge: badge)
            }
        }
    }
}

// MARK: - Card
struct AchievementCard: View {
    let badge: Achievement

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)

            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(badge.earned ? Color.yellow.opacity(0.9) : Color.gray.opacity(0.4))
                        .frame(width: 56, height: 56)

                    Image(systemName: badge.imageName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(badge.earned ? .black : .white.opacity(0.8))
                        .shadow(radius: badge.earned ? 0 : 2)
                }
                .shadow(color: badge.earned ? .yellow.opacity(0.4) : .clear, radius: 10, y: 2)

                Text(badge.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(badge.earned ? "Unlocked ✓" : "Locked 🔒")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(10)

            // Locked veil
            if !badge.earned {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.25))
            }
        }
        .frame(height: 120)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        .overlay(alignment: .topTrailing) {
            if !badge.earned {
                Image(systemName: "lock.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(6)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}

