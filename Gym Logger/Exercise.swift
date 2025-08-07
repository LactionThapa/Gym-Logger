import Foundation

struct ExerciseSet: Codable, Identifiable {
    var id = UUID()
    var targetReps: Int
    var completedReps: Int?
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "targetReps": targetReps,
            "completedReps": completedReps as Any
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> ExerciseSet? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let targetReps = dict["targetReps"] as? Int else {
            return nil
        }
        
        let completedReps = dict["completedReps"] as? Int
        return ExerciseSet(id: id, targetReps: targetReps, completedReps: completedReps)
    }
}

struct Exercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var weight: Double
    var sets: [ExerciseSet]
    var type: ExerciseType = .custom
    
    init(id: UUID = UUID(), name: String, weight: Double, sets: [ExerciseSet], type: ExerciseType = .custom) {
        self.id = id
        self.name = name
        self.weight = weight
        self.sets = sets
        self.type = type
    }
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "name": name,
            "weight": weight,
            "type": type.rawValue,
            "sets": sets.map { $0.toDictionary() }
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Exercise? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = dict["name"] as? String,
              let weight = dict["weight"] as? Double,
              let setDicts = dict["sets"] as? [[String: Any]],
              let typeString = dict["type"] as? String,
              let type = ExerciseType(rawValue: typeString)
        else {
            return nil
        }
        
        let sets = setDicts.compactMap { ExerciseSet.fromDictionary($0) }
        return Exercise(id: id, name: name, weight: weight, sets: sets, type: type)
    }
}
