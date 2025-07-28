import Foundation

struct UserProfile: Codable {
    var profileName: String
    var xp: Int
    var profilePicURL: String?
    var achievements: [String]
}
