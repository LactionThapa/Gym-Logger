import Foundation

struct Achievement: Identifiable, Codable {
    let id: UUID = UUID()
    let title: String
    let description: String
    let earned: Bool
    let dateEarned: Date?
    let imageName: String
}
