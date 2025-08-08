import Foundation

struct Achievement: Identifiable, Codable {
    var id: String
    let title: String
    let description: String
    var earned: Bool
    var dateEarned: Date?
    let imageName: String

    init(
        id: String,
        title: String,
        description: String,
        earned: Bool = false,
        dateEarned: Date? = nil,
        imageName: String,
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.earned = earned
        self.dateEarned = dateEarned
        self.imageName = imageName
    }
}

