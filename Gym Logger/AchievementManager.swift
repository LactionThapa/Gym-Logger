import Foundation
import Combine

class AchievementManager: ObservableObject {
    @Published var achievements: [Achievement] = []

    init() {
        loadAchievements()
    }

    func loadAchievements() {
        achievements = [
            Achievement(title: "First Workout",
                        description: "Log your first workout.",
                        earned: false,
                        dateEarned: nil,
                        imageName: "1.circle"),
            
            Achievement(title: "5 Workouts",
                        description: "Log 5 workouts.",
                        earned: false,
                        dateEarned: nil,
                        imageName: "5.circle"),
            
            Achievement(title: "10,000 KG Lifted",
                        description: "Lift a total of 10,000 kg.",
                        earned: false,
                        dateEarned: nil,
                        imageName: "scalemass"),
        ]
    }

    func evaluateAchievements(using workouts: [Workout]) {
        let workoutCount = workouts.count
        let totalWeight = workouts
            .flatMap { $0.exercises }
            .reduce(0.0) { $0 + ($1.weight * Double($1.sets.count)) }

        for i in achievements.indices {
            if achievements[i].earned { continue }

            switch achievements[i].title {
            case "First Workout":
                if workoutCount >= 1 {
                    unlock(&achievements[i])
                }
            case "5 Workouts":
                if workoutCount >= 5 {
                    unlock(&achievements[i])
                }
            case "10,000 KG Lifted":
                if totalWeight >= 10_000 {
                    unlock(&achievements[i])
                }
            default: break
            }
        }
    }

    private func unlock(_ achievement: inout Achievement) {
        achievement = Achievement(
            title: achievement.title,
            description: achievement.description,
            earned: true,
            dateEarned: Date(),
            imageName: achievement.imageName
        )
    }
}
