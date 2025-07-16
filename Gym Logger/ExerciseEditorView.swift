import SwiftUI

struct ExerciseEditorView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (Exercise) -> Void

    @State private var name: String = ""
    @State private var weight: String = ""
    @State private var setCount: Int = 3
    @State private var reps: [String] = ["", "", ""]

    var body: some View {
        NavigationView {
            Form {
                TextField("Exercise Name", text: $name)
                TextField("Weight (kg)", text: $weight)
                    .keyboardType(.decimalPad)

                Stepper("Sets: \(setCount)", value: $setCount, in: 1...10, onEditingChanged: { _ in
                    updateRepsArray()
                })

                ForEach(0..<setCount, id: \.self) { index in
                    TextField("Reps for Set \(index + 1)", text: $reps[index])
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Exercise")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weightVal = Double(weight),
                           let repsInt = reps.compactMap({ Int($0) }),
                           repsInt.count == setCount {
                            let exercise = Exercise(name: name, weight: weightVal, sets: repsInt)
                            onSave(exercise)
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func updateRepsArray() {
        if reps.count < setCount {
            reps.append(contentsOf: Array(repeating: "", count: setCount - reps.count))
        } else if reps.count > setCount {
            reps.removeLast(reps.count - setCount)
        }
    }
}