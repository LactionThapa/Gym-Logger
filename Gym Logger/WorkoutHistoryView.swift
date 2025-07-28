import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @State private var searchText = ""

    var filteredWorkouts: [Workout] {
        guard !searchText.isEmpty else { return workoutStorage.history }
        return workoutStorage.history.compactMap { workout in
            let filteredExercises = workout.exercises.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
            if !filteredExercises.isEmpty {
                var w = workout
                w.exercises = filteredExercises
                return w
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    ForEach(workoutStorage.history) { workout in
                        Section(header: Text(workout.date.formatted())) {
                            ForEach(workout.exercises) { ex in
                                VStack(alignment: .leading) {
                                    Text(ex.name).bold()
                                    Text("Weight: \(ex.weight, specifier: "%.1f") kg")
                                    Text("Reps: \(ex.sets.map { $0.completedReps.map(String.init) ?? "-" }.joined(separator: ", "))")
                                    
                                    NavigationLink(value: ex.name) {
                                        Text("View Progress")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteWorkout)
                } else {
                    ForEach(filteredWorkouts) { workout in
                        Section(header: Text(workout.date.formatted())) {
                            ForEach(workout.exercises) { ex in
                                VStack(alignment: .leading) {
                                    Text(ex.name).bold()
                                    Text("Weight: \(ex.weight, specifier: "%.1f") kg")
                                    Text("Reps: \(ex.sets.map { $0.completedReps.map(String.init) ?? "-" }.joined(separator: ", "))")
                                    
                                    NavigationLink(value: ex.name) {
                                        Text("View Progress")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.top, 4)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout History")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationDestination(for: String.self) { exerciseName in
                ProgressChartView(exerciseName: exerciseName, history: workoutStorage.history)
            }
            .toolbar {
                EditButton()
            }
        }
    }

    private func deleteWorkout(at offsets: IndexSet) {
        workoutStorage.delete(at: offsets)
    }
}
