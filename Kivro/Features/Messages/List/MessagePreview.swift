import Foundation

struct MessagePreview {
    let userIdentifier: String
    let name: String
    let message: String
    let avatarName: String
    let updatedAt: Date

    var displayedTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: updatedAt)
    }
}
