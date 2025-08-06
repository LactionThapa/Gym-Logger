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
                Section(header:
                            Text("Built-In")
                    .foregroundColor(.white)
                    .font(.headline)) {
                    ForEach(filteredExercises.filter { $0.type == .builtIn }) { ex in
                        ExerciseRow(ex: ex)
                    }
                }

                Section(header:
                            Text("Custom")
                    .foregroundColor(.white)
                    .font(.headline)) {
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
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .searchable(text: $searchText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Exercise Library")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(Color(hex: "F9AA33"))
                    }
                }
            }
            .onAppear {
                configureSearchBarAppearance()
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
import UIKit

func configureSearchBarAppearance() {
    let textFieldAppearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
    textFieldAppearance.textColor = .black
    textFieldAppearance.backgroundColor = .white
    textFieldAppearance.attributedPlaceholder = NSAttributedString(
        string: "Search",
        attributes: [.foregroundColor: UIColor.gray.withAlphaComponent(0.6)]
    )
    
    let searchBarAppearance = UISearchBar.appearance()
    searchBarAppearance.barTintColor = UIColor.black
    searchBarAppearance.tintColor = UIColor(hex: "#F9AA33")
}

