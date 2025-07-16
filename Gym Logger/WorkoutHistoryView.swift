import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage

    var body: some View {
        NavigationView {
            List {
                ForEach(workoutStorage.history) { workout in
                    Section(header: Text(workout.date.formatted())) {
                        ForEach(workout.exercises) { ex in
                            VStack(alignment: .leading) {
                                Text(ex.name).bold()
                                Text("Weight: \(ex.weight, specifier: "%.1f") kg")
                                Text("Reps: \(ex.sets.map { String($0) }.joined(separator: ", "))")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
        }
    }
}