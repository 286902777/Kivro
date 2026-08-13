import UIKit
import SnapKit

final class FeedPostCell: UICollectionViewCell {
    static let reuseIdentifier = "FeedPostCell"

    var onComments: (() -> Void)?
    var onMore: (() -> Void)?
    var onLikeChange: ((Bool) -> Int?)?
    var onAvatar: (() -> Void)?
    var onMedia: ((Int) -> Void)?

    private let avatarView = UIImageView()
    private let authorLabel = UILabel()
    private let categoryLabel = UILabel()
    private let bodyLabel = UILabel()
    private let mediaContainer = UIView()
    private let moreButton = UIButton(type: .system)
    private let commentButton = UIButton(type: .system)
    private let likeButton = UIButton(type: .system)
    private let commentIcon = UIImageView(image: UIImage(named: "kivro_comment_outline"))
    private let commentLabel = UILabel()
    private let likeIcon = UIImageView(image: UIImage(named: "kivro_like_outline"))
    private let likeLabel = UILabel()
    private let playIcon = UIImageView(image: UIImage(named: "kivro_video_play"))
    private var mediaViews: [UIImageView] = []
    private var isLiked = false
    private var representedPostIdentifier: UUID?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onComments = nil
        onMore = nil
        onLikeChange = nil
        onAvatar = nil
        onMedia = nil
        representedPostIdentifier = nil
    }

    static func preferredHeight(forMediaCount mediaCount: Int) -> CGFloat {
        let mediaHeight: CGFloat = mediaCount == 1 ? 160 : 100
        return 119 + mediaHeight + 42
    }

    func configure(with post: PostPreview, isLiked: Bool) {
        representedPostIdentifier = post.identifier
        avatarView.image = post.avatarImage ?? UIImage(named: post.avatarAssetName)
        authorLabel.text = post.displayedAuthorName
        categoryLabel.text = post.displayedCategory
        bodyLabel.text = post.displayedBody
        moreButton.isHidden = post.belongsToCurrentUser
        self.isLiked = isLiked

        mediaViews.forEach { $0.removeFromSuperview() }
        let images = post.displayedImages
        let mediaCount = post.displayedMediaCount
        mediaViews = (0..<mediaCount).map { index in
            let imageView = UIImageView(image: images.indices.contains(index) ? images[index] : nil)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 20
            imageView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            mediaContainer.addSubview(imageView)
            let size: CGFloat = mediaCount == 1 ? 160 : 100
            let x: CGFloat = mediaCount == 1 ? 0 : CGFloat(index % 3) * 104
            let y: CGFloat = mediaCount <= 3 ? 0 : CGFloat(index / 3) * 104
            imageView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(x)
                make.top.equalToSuperview().offset(y)
                make.size.equalTo(size)
            }
            return imageView
        }
        if post.isVideo, let videoURL = post.videoURL {
            KivroVideoMedia.shared.thumbnail(for: videoURL) { [weak self] thumbnail in
                guard let self,
                      representedPostIdentifier == post.identifier,
                      let thumbnail else { return }
                mediaViews.first?.image = thumbnail
            }
        }
        playIcon.isHidden = !post.isVideo
        mediaContainer.bringSubviewToFront(playIcon)

        commentLabel.text = "Comment  (\(post.commentCount))"
        likeIcon.image = UIImage(named: isLiked ? "kivro_like_filled" : "kivro_like_outline")
        likeLabel.text = String(post.likeCount)
        likeLabel.textColor = isLiked
            ? UIColor(red: 1, green: 0, blue: 0.55, alpha: 1)
            : UIColor.white.withAlphaComponent(0.6)

        let mediaHeight: CGFloat = mediaCount == 1 ? 160 : 100
        let actionTop = 119 + mediaHeight + 26
        [moreButton, commentButton, likeButton, commentIcon, commentLabel, likeIcon, likeLabel].forEach { actionView in
            actionView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(actionTop)
            }
        }
    }

    private func configureViews() {
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 26
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(showAuthor))
        )

        authorLabel.textColor = .white
        authorLabel.font = KivroTypography.inter(size: 16, weight: .bold)

        categoryLabel.textColor = .white
        categoryLabel.textAlignment = .center
        categoryLabel.backgroundColor = UIColor(red: 84 / 255, green: 177 / 255, blue: 1, alpha: 1)
        categoryLabel.layer.cornerRadius = 5
        categoryLabel.clipsToBounds = true
        categoryLabel.font = KivroTypography.inter(size: 10, weight: .medium)

        bodyLabel.textColor = .white
        bodyLabel.font = KivroTypography.inter(size: 12, weight: .bold)
        bodyLabel.numberOfLines = 3

        configureActionButton(moreButton, title: "··· More", action: #selector(showMore))
        commentButton.addTarget(self, action: #selector(showComments), for: .touchUpInside)
        likeButton.addTarget(self, action: #selector(toggleLike), for: .touchUpInside)
        [commentLabel, likeLabel].forEach { label in
            label.font = KivroTypography.inter(size: 11, weight: .medium)
            label.textColor = UIColor.white.withAlphaComponent(0.6)
        }
        [commentIcon, likeIcon].forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            imageView.alpha = 0.6
        }

        mediaContainer.addSubview(playIcon)
        mediaContainer.isUserInteractionEnabled = true
        mediaContainer.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(showMedia(_:)))
        )
        playIcon.contentMode = .scaleAspectFit
        playIcon.isHidden = true
        [avatarView, authorLabel, categoryLabel, bodyLabel, mediaContainer, moreButton, commentIcon, commentLabel, commentButton, likeIcon, likeLabel, likeButton].forEach(contentView.addSubview)

        avatarView.snp.makeConstraints { make in
            make.leading.top.equalToSuperview()
            make.size.equalTo(52)
        }
        authorLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(63)
            make.top.equalToSuperview().offset(7)
        }
        categoryLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(64)
            make.top.equalToSuperview().offset(31)
            make.width.equalTo(40)
            make.height.equalTo(16)
        }
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(2)
            make.top.equalToSuperview().offset(62)
            make.height.equalTo(45)
        }
        mediaContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview().offset(119)
            make.width.equalToSuperview()
            make.height.equalTo(160)
        }
        playIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(51)
            make.top.equalToSuperview().offset(50)
            make.size.equalTo(60)
        }
        moreButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(2)
            make.top.equalToSuperview().offset(301)
            make.height.equalTo(15)
        }
        commentButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(85)
            make.top.equalToSuperview().offset(301)
            make.width.equalTo(140)
            make.height.equalTo(22)
        }
        commentIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(86)
            make.top.equalToSuperview().offset(301)
            make.size.equalTo(14)
        }
        commentLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(107)
            make.top.equalToSuperview().offset(301)
            make.height.equalTo(15)
        }
        likeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(301)
            make.width.equalTo(80)
            make.height.equalTo(30)
        }
        likeIcon.snp.makeConstraints { make in
            make.trailing.equalTo(likeLabel.snp.leading).offset(-6)
            make.top.equalToSuperview().offset(301)
            make.size.equalTo(12)
        }
        likeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(2)
            make.top.equalToSuperview().offset(301)
            make.height.equalTo(15)
        }
    }

    private func configureActionButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
        button.titleLabel?.font = KivroTypography.inter(size: 11, weight: .medium)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    @objc private func showMore() {
        onMore?()
    }

    @objc private func showComments() {
        onComments?()
    }

    @objc private func showAuthor() {
        onAvatar?()
    }

    @objc private func showMedia(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: mediaContainer)
        let selectedIndex = mediaViews.firstIndex { $0.frame.contains(location) } ?? 0
        onMedia?(selectedIndex)
    }

    @objc private func toggleLike() {
        let requestedState = !isLiked
        guard let updatedCount = onLikeChange?(requestedState) else { return }
        isLiked = requestedState
        likeIcon.image = UIImage(named: isLiked ? "kivro_like_filled" : "kivro_like_outline")
        likeLabel.text = String(updatedCount)
        likeLabel.textColor = isLiked
            ? UIColor(red: 1, green: 0, blue: 0.55, alpha: 1)
            : UIColor.white.withAlphaComponent(0.6)
    }
}
