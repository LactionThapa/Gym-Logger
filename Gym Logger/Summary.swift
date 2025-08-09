import Foundation

struct SetXPBreakdown: Identifiable, Hashable {
    let id = UUID()
    let index: Int
    let target: Int
    let completed: Int
    let multiplier: Double
    let xp: Int
}

struct ExerciseXPBreakdown: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let weight: Double
    let sets: [SetXPBreakdown]
    var totalXP: Int { sets.reduce(0) { $0 + $1.xp } }
}

struct WorkoutSummary: Identifiable, Hashable {
    let id = UUID()
    let templateName: String
    let date: Date
    let exercises: [ExerciseXPBreakdown]
    var totalXP: Int { exercises.reduce(0) { $0 + $1.totalXP } }
}
