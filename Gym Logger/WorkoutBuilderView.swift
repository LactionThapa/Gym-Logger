import SwiftUI

struct WorkoutBuilderView: View {
    @EnvironmentObject var xpManager: XPManager
    @EnvironmentObject var workoutStorage: WorkoutStorage

    @State private var currentExercises: [Exercise] = []
    @State private var showingExerciseEditor = false

    var body: some View {
        NavigationView {
            VStack {
                List(currentExercises) { exercise in
                    VStack(alignment: .leading) {
                        Text(exercise.name).bold()
                        Text("Weight: \(exercise.weight, specifier: "%.1f") kg")
                        Text("Reps: \(exercise.sets.map { String($0) }.joined(separator: ", "))")
                    }
                }

                Button("Add Exercise") {
                    showingExerciseEditor = true
                }
                .padding()
                .sheet(isPresented: $showingExerciseEditor) {
                    ExerciseEditorView { newExercise in
                        currentExercises.append(newExercise)
                    }
                }

                Button("Log Workout") {
                    let workout = Workout(exercises: currentExercises)
                    workoutStorage.save(workout: workout)
                    xpManager.addXP(currentExercises.count * 10)
                    currentExercises.removeAll()
                }
                .padding()
            }
            .navigationTitle("Build Workout")
        }
    }
}