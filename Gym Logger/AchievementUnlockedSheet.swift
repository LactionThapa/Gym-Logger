struct AchievementUnlockedSheet: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: achievement.imageName)
                .font(.system(size: 56, weight: .bold))
            Text("Achievement Unlocked!")
                .font(.title2).bold()
            Text(achievement.title)
                .font(.headline)
            Text(achievement.description)
                .foregroundColor(.secondary)

            Button("Nice!") { onDismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }
}
