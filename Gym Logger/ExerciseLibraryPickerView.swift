import SwiftUI

struct ExerciseLibraryPickerView: View {
    @EnvironmentObject var exerciseLibrary: ExerciseLibraryStorage
    @Binding var selectedExercises: [Exercise]
    @Environment(\.dismiss) var dismiss

    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        let all = exerciseLibrary.savedExercises
        if searchText.isEmpty {
            return all
        } else {
            return all.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Built-In") {
                    ForEach(filteredExercises.filter { $0.type == .builtIn }) { ex in
                        ExerciseRow(ex: ex)
                    }
                }

                Section("Custom") {
                    ForEach(filteredExercises.filter { $0.type == .custom }) { ex in
                        ExerciseRow(ex: ex)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            exerciseLibrary.delete(exerciseLibrary.customExercises[index])
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Exercise Library")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    func ExerciseRow(ex: Exercise) -> some View {
        Button {
            selectedExercises.append(ex)
            dismiss()
        } label: {
            VStack(alignment: .leading) {
                Text(ex.name).bold()
                Text("Weight: \(ex.weight, specifier: "%.1f") kg")
                    .foregroundColor(.gray)
            }
        }
    }
}
