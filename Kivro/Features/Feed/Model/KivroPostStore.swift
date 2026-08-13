import Foundation

extension Notification.Name {
    static let kivroPostStoreDidChange = Notification.Name(
        KivroConstantMask.join("kivro.post.", "store.did.", "change")
    )
}

final class KivroPostStore {
    static let shared = KivroPostStore()

    private(set) var posts: [PostPreview] = []

    private init() {}

    func prepend(_ post: PostPreview) {
        posts.insert(post, at: 0)
        NotificationCenter.default.post(name: .kivroPostStoreDidChange, object: nil)
    }

    func removePosts(authorIdentifier: String) {
        posts.removeAll { $0.authorIdentifier == authorIdentifier }
        NotificationCenter.default.post(name: .kivroPostStoreDidChange, object: nil)
    }
}
