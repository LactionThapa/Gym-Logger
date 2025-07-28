import SwiftUI

struct TemplateDetailView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @EnvironmentObject var profileManager: UserProfileManager

    let template: WorkoutTemplate
    @State private var exercises: [Exercise]
    @State private var started = false
    @State private var showConfirmation = false
    @FocusState private var focusedField: UUID?


    init(template: WorkoutTemplate) {
        self.template = template
        _exercises = State(initialValue: template.exercises)
    }

    var body: some View {
        List {
            ForEach(exercises.indices, id: \.self) { i in
                exerciseSection(for: i)
            }
        }
        .navigationTitle(template.name)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button("Start") {
                        // Reset completedReps before starting
                        for i in exercises.indices {
                            for j in exercises[i].sets.indices {
                                exercises[i].sets[j].completedReps = nil
                            }
                        }
                        started = true
                    }
                    Spacer()
                    Button("Log") {
                        showConfirmation = true
                    }
                }
                .padding()
            }
        }
        .alert("Log this workout?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Log", role: .destructive) {
                let workout = Workout(exercises: exercises)
                workoutStorage.save(workout: workout)
                profileManager.addXP(exercises.count * 10)

                let updatedTemplate = WorkoutTemplate(id: template.id, name: template.name, exercises: exercises)
                templateStorage.updateTemplate(updatedTemplate)

                for ex in exercises {
                    exerciseLibrary.addOrUpdate(ex)
                }

                dismiss()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    // ✅ Extracted helper to simplify the body and avoid compiler issues
    private func exerciseSection(for index: Int) -> some View {
        let exercise = exercises[index]

        return Section {
            NavigationLink(destination: ProgressChartView(
                exerciseName: exercise.name,
                history: workoutStorage.history
            )) {
                Text("📈 View Progress")
                    .foregroundColor(.blue)
            }

            if started {
                HStack {
                    Text("Weight:")
                    TextField("kg", value: $exercises[index].weight, format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            } else {
                Text("Weight: \(exercise.weight, specifier: "%.1f") kg")
                    .foregroundColor(.gray)
            }

            ForEach(exercise.sets.indices, id: \.self) { j in
                HStack {
                    Text("Set \(j + 1): Target \(exercise.sets[j].targetReps) reps")
                    Spacer()
                    if started {
                        TextField("Done", value: $exercises[index].sets[j].completedReps, format: .number)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: exercises[index].sets[j].id)
                    } else {
                        Text("Not Started")
                            .foregroundColor(.gray)
                    }
                }
            }
        } header: {
            Text(exercise.name)
        }
    }
}
