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

struct AvatarLoadout: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
            
    // Persist this:
    var backgroundHex: String = "#0E1C26"

    // Use this only for UI (computed from hex)
    var background: Color {
        get { Color(hex: backgroundHex) }
        set { backgroundHex = newValue.toHex() ?? backgroundHex }
    }

    var baseBody: String = "BaseAvatar"
    var hair: String? = nil
    var top: String? = nil
    var bottom: String? = nil
    var accessory: String? = nil
}

struct AvatarItem: Identifiable {
    let id: String
    let name: String
    let requiredLevel: Int
    init(name: String, requiredLevel: Int) {
        self.id = name
        self.name = name
        self.requiredLevel = requiredLevel
    }
}

let HAIR_ITEMS: [AvatarItem] = [
    .init(name: "Hair1",  requiredLevel: 1),
    .init(name: "Hair11", requiredLevel: 2),
    .init(name: "Hair12", requiredLevel: 5),
    .init(name: "Hair13", requiredLevel: 8),
    .init(name: "Hair2",  requiredLevel: 1),
    .init(name: "Hair3",  requiredLevel: 3),
    .init(name: "Hair4",  requiredLevel: 4),
    .init(name: "Hairm1", requiredLevel: 6),
    .init(name: "Hairm2", requiredLevel: 10),
    .init(name: "Hairm4", requiredLevel: 15),
    .init(name: "Hsirb",  requiredLevel: 20),
]

let TOP_ITEMS: [AvatarItem] = [
    .init(name: "Jumper1",    requiredLevel: 1),
    .init(name: "Jumper2",    requiredLevel: 3),
    .init(name: "Jumper4",    requiredLevel: 5),
    .init(name: "Pink",       requiredLevel: 7),
    .init(name: "BLUE SHIRT", requiredLevel: 10),
    .init(name: "Green shirt",requiredLevel: 12),
]

let BOTTOM_ITEMS: [AvatarItem] = [
    .init(name: "Illustration2", requiredLevel: 1),
    .init(name: "Short1",        requiredLevel: 4),
    .init(name: "Shorts2",       requiredLevel: 8),
]

let ACCESS_ITEMS: [AvatarItem] = [
    .init(name: "Pink party glasses", requiredLevel: 10),
    .init(name: "Sunglasses",         requiredLevel: 25),
]

