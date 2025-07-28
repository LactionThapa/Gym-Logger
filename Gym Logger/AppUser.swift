import Foundation
struct AppUser: Identifiable, Codable {
    var id: String // Firebase user ID
    var username: String
    var profileName: String
    var level: Int
    var xp: Int
}
