import Foundation

enum KivroFirstHomeLoadingState {
    private(set) static var didShow = false

    static func consume() -> Bool {
        guard !didShow else { return false }
        didShow = true
        return true
    }
}
