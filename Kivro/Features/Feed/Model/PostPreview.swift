import UIKit

struct PostPreview {
    let identifier: UUID
    let authorIdentifier: String
    let authorNameKey: String?
    let authorName: String?
    let avatarAssetName: String
    let avatarImage: UIImage?
    let bodyKey: String?
    let bodyText: String?
    let mediaAssetNames: [String]
    let mediaImages: [UIImage]
    let videoURL: URL?
    let categoryKey: String?
    let category: String
    let likeCount: Int
    let commentCount: Int
    let isVideo: Bool

    init(
        identifier: UUID = UUID(),
        authorIdentifier: String,
        authorNameKey: String? = nil,
        authorName: String? = nil,
        avatarAssetName: String,
        avatarImage: UIImage? = nil,
        bodyKey: String? = nil,
        bodyText: String? = nil,
        mediaAssetNames: [String] = [],
        mediaImages: [UIImage] = [],
        videoURL: URL? = nil,
        categoryKey: String? = nil,
        category: String,
        likeCount: Int = 0,
        commentCount: Int = 0,
        isVideo: Bool = false
    ) {
        self.identifier = identifier
        self.authorIdentifier = authorIdentifier
        self.authorNameKey = authorNameKey
        self.authorName = authorName
        self.avatarAssetName = avatarAssetName
        self.avatarImage = avatarImage
        self.bodyKey = bodyKey
        self.bodyText = bodyText
        self.mediaAssetNames = mediaAssetNames
        self.mediaImages = mediaImages
        self.videoURL = videoURL
        self.categoryKey = categoryKey
        self.category = category
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.isVideo = isVideo
    }

    var displayedAuthorName: String {
        authorName ?? authorNameKey.map { NSLocalizedString($0, comment: "") } ?? "Cosplayer"
    }

    var displayedBody: String {
        bodyText ?? bodyKey.map { NSLocalizedString($0, comment: "") } ?? ""
    }

    var displayedCategory: String {
        categoryKey.map { NSLocalizedString($0, comment: "") } ?? category
    }

    var displayedImages: [UIImage] {
        if !mediaImages.isEmpty { return mediaImages }
        return mediaAssetNames.compactMap(KivroVideoMedia.shared.image(resourceName:))
    }

    var displayedMediaCount: Int {
        max(displayedImages.count, isVideo ? 1 : 0)
    }

    var belongsToCurrentUser: Bool {
        authorIdentifier == KivroSessionState.shared.currentUserIdentifier
    }

    func updatingEngagement(likeCount: Int, commentCount: Int) -> PostPreview {
        PostPreview(
            identifier: identifier,
            authorIdentifier: authorIdentifier,
            authorNameKey: authorNameKey,
            authorName: authorName,
            avatarAssetName: avatarAssetName,
            avatarImage: avatarImage,
            bodyKey: bodyKey,
            bodyText: bodyText,
            mediaAssetNames: mediaAssetNames,
            mediaImages: mediaImages,
            videoURL: videoURL,
            categoryKey: categoryKey,
            category: category,
            likeCount: likeCount,
            commentCount: commentCount,
            isVideo: isVideo
        )
    }
}
