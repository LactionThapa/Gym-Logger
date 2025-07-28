import Foundation
import SwiftUI

class ExerciseLibraryStorage: ObservableObject {
    @Published var savedExercises: [Exercise] = []

    func addIfUnique(_ exercise: Exercise) {
        if !savedExercises.contains(where: { $0.name == exercise.name && $0.weight == exercise.weight }) {
            savedExercises.append(exercise)
        }
    }
}
