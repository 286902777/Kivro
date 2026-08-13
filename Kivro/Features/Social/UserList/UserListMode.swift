import Foundation

enum UserListMode {
    case following
    case followers
    case blacklist

    var titleKey: String {
        switch self {
        case .following: return "social.following"
        case .followers: return "social.followers"
        case .blacklist: return "social.blacklist"
        }
    }
}
