import Foundation

extension WorkoutTemplate {
    static func defaultTemplates() -> [WorkoutTemplate] {

        func ex(_ name: String, _ weight: Double, _ reps: [Int]) -> Exercise {
            Exercise(
                name: name,
                weight: weight,
                sets: reps.map { ExerciseSet(targetReps: $0, completedReps: nil) }
            )
        }

        return [
            WorkoutTemplate(
                name: "Full Body Beginner",
                exercises: [
                    ex("Goblet Squat", 20, [10,10,10]),
                    ex("Bench Press", 45, [8,8,8]),
                    ex("Lat Pulldown", 40, [10,10,10]),
                    ex("Dumbbell Shoulder Press", 20, [10,10])
                ]
            ),
            WorkoutTemplate(
                name: "Push Day",
                exercises: [
                    ex("Barbell Bench Press", 65, [8,8,6]),
                    ex("Incline DB Press", 25, [10,10,10]),
                    ex("Overhead Press", 45, [8,8,8]),
                    ex("Cable Fly", 20, [12,12])
                ]
            ),
            WorkoutTemplate(
                name: "Pull Day",
                exercises: [
                    ex("Deadlift", 95, [5,5,5]),
                    ex("Bent Over Row", 65, [8,8,8]),
                    ex("Lat Pulldown", 45, [10,10,10]),
                    ex("Face Pull", 15, [15,15])
                ]
            ),
            WorkoutTemplate(
                name: "Legs",
                exercises: [
                    ex("Back Squat", 85, [5,5,5]),
                    ex("Romanian Deadlift", 75, [8,8,8]),
                    ex("Leg Press", 120, [12,12,12]),
                    ex("Calf Raise", 40, [15,15])
                ]
            )
        ]
    }
}
