import SwiftUI

struct RepsField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        TextField(label, text: $text)
            .keyboardType(.numberPad)
    }
}

struct ExerciseEditorView: View {
    var exerciseToEdit: Exercise?
    var onSave: (Exercise) -> Void

    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var weight: String
    @State private var setCount: Int
    @State private var targetReps: [String]
    @State private var uniformReps: String = ""
    @State private var showValidationError = false
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @State private var saveToLibrary: Bool = false


    private var exerciseID: UUID

    init(exerciseToEdit: Exercise? = nil, onSave: @escaping (Exercise) -> Void) {
        self.exerciseToEdit = exerciseToEdit
        self.onSave = onSave

        _name = State(initialValue: exerciseToEdit?.name ?? "")
        _weight = State(initialValue: exerciseToEdit.map { String($0.weight) } ?? "")
        _setCount = State(initialValue: exerciseToEdit?.sets.count ?? 3)
        _targetReps = State(initialValue: exerciseToEdit?.sets.map { String($0.targetReps) } ?? Array(repeating: "", count: 3))
        self.exerciseID = exerciseToEdit?.id ?? UUID()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Exercise Info")) {
                    TextField("Exercise Name", text: $name)
                    TextField("Weight (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Sets")) {
                    Stepper("Number of Sets: \(setCount)", value: $setCount, in: 1...10)
                        .onChange(of: setCount) {
                            updateRepsArray()
                        }

                    HStack {
                        TextField("Set all to...", text: $uniformReps)
                            .keyboardType(.numberPad)

                        Button("Apply") {
                            if let reps = Int(uniformReps) {
                                targetReps = Array(repeating: "\(reps)", count: setCount)
                            }
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }

                    ForEach(0..<setCount, id: \.self) { index in
                        let binding = Binding(
                            get: { targetReps[index] },
                            set: { targetReps[index] = $0 }
                        )
                        
                        RepsField(label: "Target Reps for Set \(index + 1)", text: binding)

                    }

                }
                Toggle("Save to Exercise Library", isOn: $saveToLibrary)
            }
            .navigationTitle(exerciseToEdit == nil ? "New Exercise" : "Edit Exercise")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weightVal = Double(weight) {
                            let repsInt = targetReps.compactMap { Int($0) }
                            if repsInt.count == setCount {
                                let sets = repsInt.map { ExerciseSet(targetReps: $0, completedReps: nil) }
                                let exercise = Exercise(id: exerciseToEdit?.id ?? UUID(), name: name, weight: weightVal, sets: sets)

                                if saveToLibrary {
                                    exerciseLibrary.addOrUpdate(exercise)
                                }
                                onSave(exercise)
                                dismiss()
                            }
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Invalid input", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please ensure all fields are correctly filled out. Weight must be a number and reps must be integers.")
            }
        }
    }

    private func saveExercise() {
        guard let weightVal = Double(weight),
              !name.isEmpty,
              targetReps.allSatisfy({ Int($0) != nil }) else {
            showValidationError = true
            return
        }

        let sets = targetReps.compactMap { Int($0) }.map {
            ExerciseSet(targetReps: $0, completedReps: nil)
        }

        let updatedExercise = Exercise(
            id: exerciseID,
            name: name,
            weight: weightVal,
            sets: sets
        )
        
        exerciseLibrary.addIfUnique(updatedExercise)
        onSave(updatedExercise)
        dismiss()
    }

    private func updateRepsArray() {
        if targetReps.count < setCount {
            targetReps.append(contentsOf: Array(repeating: "", count: setCount - targetReps.count))
        } else if targetReps.count > setCount {
            targetReps.removeLast(targetReps.count - setCount)
        }
    }
}
