import Foundation

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var exercises: [Exercise]
    
    init(id: UUID = UUID(), name: String, exercises: [Exercise]) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "exercises": exercises.map { $0.toDictionary() }
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> WorkoutTemplate? {
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let name = dict["name"] as? String,
              let exercisesRaw = dict["exercises"] as? [[String: Any]] else { return nil }
        
        let exercises = exercisesRaw.compactMap { Exercise.fromDictionary($0) }
        return WorkoutTemplate(id: id, name: name, exercises: exercises)
    }
}
