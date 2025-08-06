import SwiftUI

struct TemplateDetailView: View {
    @EnvironmentObject var workoutStorage: WorkoutStorage
    @EnvironmentObject var templateStorage: WorkoutTemplateStorage
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @EnvironmentObject var profileManager: UserProfileManager

    let template: WorkoutTemplate
    @State private var exercises: [Exercise]
    @State private var showConfirmation = false
    @FocusState private var focusedField: UUID?
    @State private var started = false
    
    var isWorkoutComplete: Bool {
        exercises.allSatisfy { exercise in
            exercise.sets.allSatisfy { $0.completedReps != nil }
        }
    }

    init(template: WorkoutTemplate, started: Bool = false) {
        self.template = template
        _exercises = State(initialValue: template.exercises)
        self._started = State(initialValue: started)
    }

    var body: some View {   
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(exercises.indices, id: \.self) { i in
                    exerciseSection(for: i)
                }
            }
            .padding(.vertical)
        }
        .background(Color("AppBackground"))
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(template.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    Button("Log") {
                        if isWorkoutComplete {
                            showConfirmation = true
                        }
                    }
                    .disabled(!isWorkoutComplete)
                    .opacity(isWorkoutComplete ? 1 : 0.5)
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
        .onAppear {
            if started {
                for i in exercises.indices {
                    for j in exercises[i].sets.indices {
                        exercises[i].sets[j].completedReps = nil
                    }
                }
            }
        }
    }

    // ✅ Extracted helper to simplify the body and avoid compiler issues
    private func exerciseSection(for index: Int) -> some View {
        let exercise = exercises[index]

        return VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Menu {
                    Button("Delete", role: .destructive) {
                        exercises.remove(at: index)
                    }
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.white)
                }
            }
            // Column Headers
            HStack {
                Text("Set").frame(width: 40, alignment: .leading)
                Text("Weight").frame(width: 60, alignment: .leading)
                Text("Reps").frame(width: 60, alignment: .leading)
                Spacer()
                Text("Done")
            }
            .font(.caption)
            .foregroundColor(Color.gray)
            // Set rows
            ForEach(exercises[index].sets.indices, id: \.self) { j in
                let isDone = exercises[index].sets[j].completedReps != nil
                HStack {
                    Button(action: {
                        exercises[index].sets.remove(at: j)
                    }) {
                        Circle()
                            .strokeBorder(Color(hex: "F9AA33"), lineWidth: 2)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text("\(j + 1)")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "F9AA33"))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    TextField("Weight", value: $exercises[index].weight, format: .number)
                        .keyboardType(.decimalPad)
                        .foregroundColor(isDone ? .gray : .white)
                        .frame(width: 60)
                        .disabled(isDone)

                    TextField("Reps", value: $exercises[index].sets[j].targetReps, format: .number)
                        .keyboardType(.numberPad)
                        .foregroundColor(isDone ? .gray : .white)
                        .frame(width: 60)
                        .disabled(isDone)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { isDone},
                        set: { isChecked in
                            exercises[index].sets[j].completedReps = isChecked ? exercises[index].sets[j].targetReps : nil
                        }
                    ))
                    .labelsHidden()
                }
            }
            Button(action: {
                exercises[index].sets.append(ExerciseSet(targetReps: 10, completedReps: nil))
            }) {
                Text("Add Set")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "F9AA33"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(hex: "232F34"))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}
