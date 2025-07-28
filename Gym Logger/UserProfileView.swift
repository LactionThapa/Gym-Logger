import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var xpManager: XPManager
    @EnvironmentObject var workoutStorage: WorkoutStorage

    @State private var userName: String = "Your Name"
    @State private var showingImagePicker = false
    @State private var profileImage: Image? = nil
    @State private var inputImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Picture
                    ZStack {
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
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

                    // Name
                    TextField("Enter Name", text: $userName)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // XP & Level
                    VStack(spacing: 6) {
                        Text("Level \(xpManager.level)")
                            .font(.headline)

                        ProgressView(value: Double(xpManager.currentXP), total: Double(xpManager.requiredXP))
                            .accentColor(.green)
                            .padding(.horizontal)

                        Text("\(xpManager.currentXP) / \(xpManager.requiredXP) XP")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Divider().padding(.vertical)

                    // Max Weights per Exercise
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
                .padding()
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _ in loadImage() }
        }
    }

    private func topWeights() -> [(String, Double)] {
        var maxMap: [String: Double] = [:]

        for workout in workoutStorage.history {
            for exercise in workout.exercises {
                let maxWeight = exercise.weight
                if let currentMax = maxMap[exercise.name] {
                    maxMap[exercise.name] = max(currentMax, maxWeight)
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
    }
}
