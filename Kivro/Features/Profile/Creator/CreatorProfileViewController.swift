import UIKit
import SnapKit

final class CreatorProfileViewController: KivroViewController {
    private let creatorIdentifier: String
    private let currentUserIdentifier: String
    private let followButton = UIButton(type: .system)
    private let followingCountLabel = UILabel()
    private let followerCountLabel = UILabel()
    private var isFollowing = false
    private var didRunQAChatCheck = false
    private var postLikeIcons: [String: UIImageView] = [:]
    private var postLikeLabels: [String: UILabel] = [:]
    private var postLikeButtons: [String: UIButton] = [:]
    private var creatorUser: KivroStoredUser? {
        KivroSeedDatabase.shared.user(identifier: creatorIdentifier)
    }
    private var creatorPosts: [KivroStoredPost] {
        guard !KivroSeedDatabase.shared.isBlocked(
            sourceIdentifier: currentUserIdentifier,
            targetIdentifier: creatorIdentifier
        ) else { return [] }
        return KivroSeedDatabase.shared.posts(authorIdentifier: creatorIdentifier)
    }

    init(creatorIdentifier: String, currentUserIdentifier: String) {
        self.creatorIdentifier = creatorIdentifier
        self.currentUserIdentifier = currentUserIdentifier
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        isFollowing = KivroSeedDatabase.shared.isFollowing(
            sourceIdentifier: currentUserIdentifier,
            targetIdentifier: creatorIdentifier
        )
        configureLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(postEngagementDidChange),
            name: .kivroPostEngagementDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshSocialState()
        refreshPostLikes()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if DEBUG
        guard ProcessInfo.processInfo.environment["KIVRO_QA_SCREEN"] == "creator_chat_locked",
              !didRunQAChatCheck else { return }
        didRunQAChatCheck = true
        showChat()
#endif
    }

    private func configureLayout() {
        guard let creatorUser else {
            KivroToastPresenter.show(message: "Unable to load this profile.", in: view)
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            return
        }
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        let contentView = UIView()
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(105)
            make.leading.trailing.bottom.equalToSuperview()
        }
        let posts = creatorPosts
        let contentHeight = max(707, 228 + CGFloat(posts.count) * 344 + 20)
        contentView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
            make.height.equalTo(contentHeight)
        }

        configureProfileHeader(in: contentView, user: creatorUser)
        for (index, post) in posts.enumerated() {
            configurePost(
                in: contentView,
                post: post,
                user: creatorUser,
                top: 228 + CGFloat(index) * 344
            )
        }
        configureFixedNavigation()
    }

    private func configureFixedNavigation() {
        let backButton = KivroBackButton()
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(54)
            make.size.equalTo(40)
        }

        guard creatorIdentifier != currentUserIdentifier else { return }
        let moreButton = circleButton(imageName: "ellipsis", action: #selector(showMore))
        view.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(54)
            make.size.equalTo(40)
        }
    }

    private func configureProfileHeader(in contentView: UIView, user: KivroStoredUser) {
        let avatar = UIImageView(image: UIImage(named: user.avatarAssetName))
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 50
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(100)
        }

        addLabel(
            to: contentView,
            text: user.username,
            x: 135,
            y: 14,
            size: 32,
            weight: .bold
        )
        configureCountLabel(followingCountLabel, in: contentView, x: 133)
        configureCountLabel(followerCountLabel, in: contentView, x: 244)
        addLabel(to: contentView, text: "FOLLOWING", x: 132, y: 97, size: 14, weight: .medium, alpha: 0.5)
        addLabel(to: contentView, text: "FOLLOWERS", x: 243, y: 97, size: 14, weight: .medium, alpha: 0.5)

        followButton.titleLabel?.font = KivroTypography.inter(size: 18, weight: .bold)
        followButton.backgroundColor = .clear
        followButton.layer.cornerRadius = 16
        followButton.layer.borderWidth = 2
        followButton.addTarget(self, action: #selector(toggleFollow), for: .touchUpInside)
        contentView.addSubview(followButton)
        followButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalTo(contentView.snp.centerX).offset(-10)
            make.top.equalToSuperview().offset(144)
            make.height.equalTo(54)
        }
        refreshSocialState()

        let messageButton = KivroProfileEditButton()
        messageButton.setTitle("MESSAGE", for: .normal)
        messageButton.addTarget(self, action: #selector(showChat), for: .touchUpInside)
        contentView.addSubview(messageButton)
        messageButton.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.centerX).offset(10)
            make.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(144)
            make.height.equalTo(54)
        }
    }

    private func configurePost(
        in contentView: UIView,
        post: KivroStoredPost,
        user: KivroStoredUser,
        top: CGFloat
    ) {
        let avatar = UIImageView(image: UIImage(named: user.avatarAssetName))
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 26
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(21)
            make.top.equalToSuperview().offset(top)
            make.size.equalTo(52)
        }

        addLabel(
            to: contentView,
            text: user.username,
            x: 84,
            y: top + 7,
            size: 16,
            weight: .bold
        )

        let category = UILabel()
        category.text = post.category
        category.textColor = .white
        category.textAlignment = .center
        category.font = KivroTypography.inter(size: 10, weight: .medium)
        category.backgroundColor = UIColor(red: 84 / 255, green: 177 / 255, blue: 1, alpha: 1)
        category.layer.cornerRadius = 5
        category.clipsToBounds = true
        contentView.addSubview(category)
        category.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(85)
            make.top.equalToSuperview().offset(top + 31)
            make.width.equalTo(max(40, post.category.count * 8 + 16))
            make.height.equalTo(16)
        }

        let body = UILabel()
        body.text = post.body
        body.textColor = .white
        body.font = KivroTypography.inter(size: 12, weight: .bold)
        body.numberOfLines = 3
        contentView.addSubview(body)
        body.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(23)
            make.top.equalToSuperview().offset(top + 62)
            make.height.equalTo(45)
        }

        let image = UIImageView(image: KivroVideoMedia.shared.image(resourceName: post.mediaAssetName))
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 20
        contentView.addSubview(image)
        image.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(21)
            make.top.equalToSuperview().offset(top + 119)
            make.size.equalTo(160)
        }

        let mediaButton = UIButton(type: .custom)
        mediaButton.accessibilityLabel = post.isVideo ? "Play video" : "View image"
        mediaButton.addAction(
            UIAction { [weak self] _ in
                self?.openMedia(post: post)
            },
            for: .touchUpInside
        )
        contentView.addSubview(mediaButton)
        mediaButton.snp.makeConstraints { make in
            make.edges.equalTo(image)
        }

        let actionY = top + 301
        if creatorIdentifier != currentUserIdentifier {
            let moreButton = UIButton(type: .system)
            moreButton.setTitle("··· More", for: .normal)
            moreButton.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .normal)
            moreButton.titleLabel?.font = KivroTypography.inter(size: 11, weight: .medium)
            moreButton.contentHorizontalAlignment = .left
            moreButton.addTarget(self, action: #selector(showMore), for: .touchUpInside)
            contentView.addSubview(moreButton)
            moreButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(23)
                make.top.equalToSuperview().offset(actionY - 5)
                make.width.equalTo(72)
                make.height.equalTo(26)
            }
        }

        let commentIcon = UIImageView(image: UIImage(named: "kivro_comment_outline"))
        commentIcon.contentMode = .scaleAspectFit
        commentIcon.alpha = 0.6
        contentView.addSubview(commentIcon)
        commentIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(107)
            make.top.equalToSuperview().offset(actionY + 1)
            make.size.equalTo(14)
        }

        addLabel(
            to: contentView,
            text: "Comment  (\(post.commentCount))",
            x: 128,
            y: actionY,
            size: 11,
            weight: .medium,
            alpha: 0.6
        )

        if let postIdentifier = UUID(uuidString: post.identifier) {
            let commentButton = UIButton(type: .custom)
            commentButton.accessibilityLabel = "View comments"
            commentButton.addAction(
                UIAction { [weak self] _ in
                    self?.showComments(postIdentifier: postIdentifier)
                },
                for: .touchUpInside
            )
            contentView.addSubview(commentButton)
            commentButton.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(96)
                make.top.equalToSuperview().offset(actionY - 7)
                make.width.equalTo(170)
                make.height.equalTo(32)
            }
        }

        let likeIcon = UIImageView(image: UIImage(named: "kivro_like_outline"))
        likeIcon.contentMode = .scaleAspectFit
        likeIcon.alpha = 0.6
        contentView.addSubview(likeIcon)

        let likeLabel = addLabel(
            to: contentView,
            text: String(post.likeCount),
            x: 339,
            y: actionY,
            size: 11,
            weight: .medium,
            alpha: 0.6
        )
        likeLabel.snp.remakeConstraints { make in
            make.trailing.equalToSuperview().inset(22)
            make.top.equalToSuperview().offset(actionY)
        }
        likeIcon.snp.makeConstraints { make in
            make.trailing.equalTo(likeLabel.snp.leading).offset(-6)
            make.top.equalToSuperview().offset(actionY)
            make.size.equalTo(12)
        }

        let likeButton = UIButton(type: .custom)
        likeButton.accessibilityLabel = "Like post"
        likeButton.accessibilityIdentifier = post.identifier
        likeButton.addTarget(self, action: #selector(togglePostLike(_:)), for: .touchUpInside)
        contentView.addSubview(likeButton)
        likeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(actionY - 10)
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        postLikeIcons[post.identifier] = likeIcon
        postLikeLabels[post.identifier] = likeLabel
        postLikeButtons[post.identifier] = likeButton
        refreshPostLike(identifier: post.identifier)
    }

    private func refreshPostLikes() {
        postLikeLabels.keys.forEach(refreshPostLike(identifier:))
    }

    private func refreshPostLike(identifier: String) {
        let isLiked = KivroSeedDatabase.shared.isPostLiked(
            postIdentifier: identifier,
            userIdentifier: currentUserIdentifier
        )
        let count = KivroSeedDatabase.shared.engagementCounts(postIdentifier: identifier).likes
        postLikeIcons[identifier]?.image = UIImage(
            named: isLiked ? "kivro_like_filled" : "kivro_like_outline"
        )
        postLikeLabels[identifier]?.text = String(count)
        postLikeLabels[identifier]?.textColor = isLiked
            ? UIColor(red: 1, green: 0, blue: 0.55, alpha: 1)
            : UIColor.white.withAlphaComponent(0.6)
        postLikeButtons[identifier]?.accessibilityValue = isLiked ? "Liked" : "Not liked"
    }

    @discardableResult
    private func addLabel(
        to container: UIView,
        text: String,
        x: CGFloat,
        y: CGFloat,
        size: CGFloat,
        weight: UIFont.Weight,
        italic: Bool = false,
        alpha: CGFloat = 1
    ) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(alpha)
        label.font = KivroTypography.inter(size: size, weight: weight, italic: italic)
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(x)
            make.top.equalToSuperview().offset(y)
        }
        return label
    }

    private func circleButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func configureCountLabel(_ label: UILabel, in container: UIView, x: CGFloat) {
        label.textColor = .white
        label.font = KivroTypography.inter(size: 28, weight: .bold, italic: true)
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(x)
            make.top.equalToSuperview().offset(62)
        }
    }

    private func refreshSocialState() {
        isFollowing = KivroSeedDatabase.shared.isFollowing(
            sourceIdentifier: currentUserIdentifier,
            targetIdentifier: creatorIdentifier
        )
        let counts = KivroSeedDatabase.shared.socialCounts(for: creatorIdentifier)
        followingCountLabel.text = Self.compactCount(counts.following)
        followerCountLabel.text = Self.compactCount(counts.followers)

        let normalColor = UIColor(red: 225 / 255, green: 217 / 255, blue: 240 / 255, alpha: 1)
        let followedColor = UIColor(red: 139 / 255, green: 132 / 255, blue: 153 / 255, alpha: 1)
        followButton.setTitle(isFollowing ? "FOLLOWED" : "FOLLOW", for: .normal)
        followButton.setTitleColor(isFollowing ? followedColor : normalColor, for: .normal)
        followButton.layer.borderColor = (isFollowing ? followedColor : normalColor).cgColor
        followButton.accessibilityValue = isFollowing ? "Following" : "Not following"
    }

    private static func compactCount(_ count: Int) -> String {
        guard count >= 1_000 else { return String(count) }
        return String(format: "%.1f K", Double(count) / 1_000)
    }

    @objc private func toggleFollow() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        do {
            try KivroSeedDatabase.shared.setFollowing(
                !isFollowing,
                sourceIdentifier: currentUserIdentifier,
                targetIdentifier: creatorIdentifier
            )
            refreshSocialState()
        } catch {
            KivroToastPresenter.show(message: "Unable to update follow status.", in: view)
        }
    }

    @objc private func togglePostLike(_ sender: UIButton) {
        guard KivroAccountAccess.requireAccount(from: self),
              let identifier = sender.accessibilityIdentifier else { return }
        let requestedState = !KivroSeedDatabase.shared.isPostLiked(
            postIdentifier: identifier,
            userIdentifier: currentUserIdentifier
        )
        do {
            _ = try KivroSeedDatabase.shared.setPostLiked(
                requestedState,
                postIdentifier: identifier,
                userIdentifier: currentUserIdentifier
            )
            refreshPostLike(identifier: identifier)
        } catch {
            KivroToastPresenter.show(message: "Unable to update this like.", in: view)
        }
    }

    @objc private func postEngagementDidChange() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.refreshPostLikes()
            }
            return
        }
        refreshPostLikes()
    }

    @objc private func showChat() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        guard KivroSeedDatabase.shared.canChat(
            between: currentUserIdentifier,
            and: creatorIdentifier
        ) else {
            KivroToastPresenter.show(
                message: KivroStrings.value("social.chat_requires_mutual"),
                in: view
            )
            return
        }
        navigationController?.pushViewController(
            ChatViewController(targetUserIdentifier: creatorIdentifier),
            animated: true
        )
    }

    private func showComments(postIdentifier: UUID) {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        present(CommentsViewController(postIdentifier: postIdentifier), animated: true)
    }

    private func openMedia(post: KivroStoredPost) {
        if post.isVideo {
            guard let videoURL = KivroVideoMedia.shared.bundledURL(
                resourceName: post.mediaAssetName
            ) else { return }
            navigationController?.pushViewController(
                KivroVideoPlayerViewController(videoURL: videoURL),
                animated: true
            )
            return
        }
        guard let image = KivroVideoMedia.shared.image(resourceName: post.mediaAssetName) else { return }
        navigationController?.pushViewController(
            KivroImagePreviewViewController(image: image),
            animated: true
        )
    }

    @objc private func showMore() {
        guard creatorIdentifier != currentUserIdentifier else { return }
        let controller = MoreActionsViewController(
            targetUserIdentifier: creatorIdentifier,
            currentUserIdentifier: currentUserIdentifier
        )
        controller.onBlocked = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        present(controller, animated: true)
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}
