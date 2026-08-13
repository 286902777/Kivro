import UIKit

enum KivroTabItem: Int, CaseIterable {
    case home
    case persona
    case messages
    case profile

    var imageName: String {
        switch self {
        case .home: return "kivro_tab_home_default"
        case .persona: return "kivro_tab_persona_default"
        case .messages: return "kivro_tab_messages_default"
        case .profile: return "kivro_tab_profile_default"
        }
    }

    var selectedImageName: String {
        switch self {
        case .home: return "kivro_tab_home_selected"
        case .persona: return "kivro_tab_persona_selected"
        case .messages: return "kivro_tab_messages_selected"
        case .profile: return "kivro_tab_profile_selected"
        }
    }

    var fallbackSymbolName: String {
        switch self {
        case .home: return "house.fill"
        case .persona: return "flame.fill"
        case .messages: return "ellipsis.message.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .home: return "Radar"
        case .persona: return "Showcase"
        case .messages: return "Messages"
        case .profile: return "Profile"
        }
    }
}
