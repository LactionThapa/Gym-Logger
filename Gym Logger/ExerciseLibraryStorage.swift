import Foundation
import SwiftUI

enum ExerciseType: String, Codable {
    case builtIn
    case custom
}

class ExerciseLibraryStorage: ObservableObject {
    @Published var savedExercises: [Exercise] = []
    
    var customExercises: [Exercise] {
        savedExercises.filter { $0.type == .custom }
    }

    var builtInExercises: [Exercise] {
        savedExercises.filter { $0.type == .builtIn }
    }


    func addOrUpdate(_ exercise: Exercise) {
        if let index = savedExercises.firstIndex(where: { $0.id == exercise.id }) {
            savedExercises[index] = exercise
        } else {
            savedExercises.append(exercise)
        }
        persist()
    }
    
    func addIfUnique(_ exercise: Exercise) {
        if !savedExercises.contains(where: { $0.id == exercise.id }) {
            savedExercises.append(exercise)
        }
    }
    
    func delete(_ exercise: Exercise) {
            savedExercises.removeAll { $0.id == exercise.id }
            persist()
        }

    func persist() {
        let customOnly = savedExercises.filter { $0.type == .custom }
        if let data = try? JSONEncoder().encode(customOnly) {
            UserDefaults.standard.set(data, forKey: "exercise_library")
        }
    }

    func load() {
        var loadedCustoms: [Exercise] = []
        
        if let data = UserDefaults.standard.data(forKey: "exercise_library"),
            let decoded = try? JSONDecoder().decode([Exercise].self, from: data) {
            loadedCustoms = decoded
        }
        let builtIns: [Exercise] = [
                Exercise(name: "Bench Press", weight: 0, sets: [], type: .builtIn),
                Exercise(name: "Deadlift", weight: 0, sets: [], type: .builtIn),
                Exercise(name: "Squat", weight: 0, sets: [], type: .builtIn)
            ]
        let existingNames = Set(loadedCustoms.map { $0.name })
        let filteredBuiltIns = builtIns.filter { !existingNames.contains($0.name) }
        savedExercises = filteredBuiltIns + loadedCustoms
    }

    init() {
        load()
    }
}
