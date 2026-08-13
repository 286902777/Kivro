import Foundation

enum KivroStrings {
    static func value(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}
