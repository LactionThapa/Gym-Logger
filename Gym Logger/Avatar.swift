import Foundation
import SwiftUI
enum AvatarCategory: String, CaseIterable, Identifiable {
    case hair, tops, bottoms, accessories
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hair: return "person.crop.circle.badge.exclamationmark" // swap to your SF Symbol
        case .tops: return "tshirt"
        case .bottoms: return "figure"
        case .accessories: return "sunglasses"
        }
    }

    var title: String {
        switch self {
        case .hair: return "Hair"
        case .tops: return "Tops"
        case .bottoms: return "Bottoms"
        case .accessories: return "Accessories"
        }
    }
}

struct AvatarLoadout {
    var background: Color = Color(hex: "0E1C26")
    var baseBody: String = "BaseAvatar"   // ⚠️ your file name includes a space
    var hair: String? = nil
    var top: String? = nil
    var bottom: String? = nil
    var accessory: String? = nil
}
