import Foundation

struct UserProfile: Codable {
    var username: String = "" 
    var profileName: String = "Your Name"
    var profilePicURL: String? = nil
    var xp: Int = 0
    var level: Int = 1
    var achievements: [String] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastWorkoutDate: Date? = nil
}
