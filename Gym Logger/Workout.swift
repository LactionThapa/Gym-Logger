import Foundation
import FirebaseFirestore

struct Workout: Identifiable, Codable {
    var id: UUID
    let date: Date
    var exercises: [Exercise]
    var templateName: String  // ✅ Now non-optional

    init(id: UUID = UUID(), date: Date = Date(), exercises: [Exercise], templateName: String) {
        self.id = id
        self.date = date
        self.exercises = exercises
        self.templateName = templateName
    }

    func toDictionary() -> [String: Any] {
        return [
            "id": id.uuidString,
            "date": Timestamp(date: date),
            "exercises": exercises.map { $0.toDictionary() },
            "templateName": templateName
        ]
    }

    static func fromDictionary(_ dict: [String: Any]) -> Workout? {
        guard
            let idString = dict["id"] as? String,
            let id = UUID(uuidString: idString),
            let timestamp = dict["date"] as? Timestamp,
            let exerciseDicts = dict["exercises"] as? [[String: Any]],
            let templateName = dict["templateName"] as? String  // ✅ Now required
        else {
            return nil
        }

        let exercises = exerciseDicts.compactMap { Exercise.fromDictionary($0) }

        return Workout(id: id, date: timestamp.dateValue(), exercises: exercises, templateName: templateName)
    }
}
