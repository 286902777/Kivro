import Foundation

struct CommentPreview: Hashable {
    let identifier: UUID
    let authorIdentifier: String
    let authorName: String
    let avatarAssetName: String
    let body: String

    init(
        identifier: UUID = UUID(),
        authorIdentifier: String,
        authorName: String,
        avatarAssetName: String,
        body: String
    ) {
        self.identifier = identifier
        self.authorIdentifier = authorIdentifier
        self.authorName = authorName
        self.avatarAssetName = avatarAssetName
        self.body = body
    }

    nonisolated init(storedComment: KivroStoredComment) {
        identifier = UUID(uuidString: storedComment.identifier) ?? UUID()
        authorIdentifier = storedComment.authorIdentifier
        authorName = storedComment.authorName
        avatarAssetName = storedComment.avatarAssetName
        body = storedComment.body
    }
}
