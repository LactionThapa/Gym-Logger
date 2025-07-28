import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    var id: UUID
    let date: Date
    var exercises: [Exercise]
    
    init(id: UUID = UUID(), date: Date = Date(), exercises: [Exercise]) {
        self.id = id
        self.date = date
        self.exercises = exercises
    }
    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "date": Timestamp(date: date),
            "exercises": exercises.map { $0.toDictionary() }
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> Workout? {
        guard
            let idString = dict["id"] as? String,
            let id = UUID(uuidString: idString),
            let timestamp = dict["date"] as? Timestamp,
            let exerciseDicts = dict["exercises"] as? [[String: Any]]
        else {
            return nil
        }
        
        let exercises = exerciseDicts.compactMap { Exercise.fromDictionary($0) }
        return Workout(id: id, date: timestamp.dateValue(), exercises: exercises)
    }
}

