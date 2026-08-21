import UIKit
import SnapKit

final class ProfileViewController: KivroViewController,
                                   UICollectionViewDataSource,
                                   UICollectionViewDelegateFlowLayout {
    private let contentView = UIView()
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let profileAvatarView = UIImageView()
    private let profileNameLabel = UILabel()
    private let followingCountLabel = UILabel()
    private let followerCountLabel = UILabel()
    private let coinBalanceLabel = UILabel()
    private let emptyWorkLabel = UILabel()
    private lazy var workCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeWorkLayout()
    )
    private var posts: [PostPreview] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
        observeDataChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshProfile()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.width.equalToSuperview().priority(.high)
            make.width.lessThanOrEqualTo(430)
        }

        configureHeader()
        configureRechargeCard()
        configureActions()
        configureWorkList()
    }

    private func observeDataChanges() {
        let notifications: [Notification.Name] = [
            .kivroCoinBalanceDidChange,
            .kivroProfileDidChange,
            .kivroPostStoreDidChange,
            .kivroPostEngagementDidChange,
            .kivroFollowStateDidChange
        ]
        notifications.forEach { name in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(profileDataDidChange),
                name: name,
                object: nil
            )
        }
    }

    private func configureHeader() {
        profileAvatarView.image = UIImage(named: "kivro_profile_header_avatar")
        profileAvatarView.contentMode = .scaleAspectFill
        profileAvatarView.clipsToBounds = true
        profileAvatarView.layer.cornerRadius = 50
        contentView.addSubview(profileAvatarView)
        profileAvatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(63)
            make.size.equalTo(100)
        }

        configureLabel(
            profileNameLabel,
            text: "",
            x: 135,
            y: 63,
            font: KivroTypography.inter(size: 32, weight: .bold)
        )
        configureLabel(
            followingCountLabel,
            text: "",
            x: 133,
            y: 111,
            font: KivroTypography.inter(size: 28, weight: .bold, italic: true)
        )
        configureLabel(
            followerCountLabel,
            text: "",
            x: 244,
            y: 111,
            font: KivroTypography.inter(size: 28, weight: .bold, italic: true)
        )
        addLabel(
            text: "FOLLOWING",
            x: 132,
            y: 146,
            font: KivroTypography.inter(size: 14, weight: .medium),
            alpha: 0.5
        )
        addLabel(
            text: "FOLLOWERS",
            x: 243,
            y: 146,
            font: KivroTypography.inter(size: 14, weight: .medium),
            alpha: 0.5
        )

        let followingButton = UIButton(type: .custom)
        followingButton.accessibilityLabel = "Following"
        followingButton.addTarget(self, action: #selector(showFollowing), for: .touchUpInside)
        contentView.addSubview(followingButton)
        followingButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(124)
            make.top.equalToSuperview().offset(105)
            make.width.equalTo(112)
            make.height.equalTo(64)
        }

        let followersButton = UIButton(type: .custom)
        followersButton.accessibilityLabel = "Followers"
        followersButton.addTarget(self, action: #selector(showFollowers), for: .touchUpInside)
        contentView.addSubview(followersButton)
        followersButton.snp.makeConstraints { make in
            make.leading.equalTo(followingButton.snp.trailing)
            make.trailing.equalToSuperview().inset(12)
            make.top.height.equalTo(followingButton)
        }
    }

    private func configureRechargeCard() {
        let card = KivroRechargeCardButton()
        card.addTarget(self, action: #selector(showRecharge), for: .touchUpInside)
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(190)
            make.height.equalTo(104)
        }

        let gift = UIImageView(image: UIImage(named: "kivro_coin_stack"))
        gift.contentMode = .scaleAspectFit
        contentView.addSubview(gift)
        gift.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(5)
            make.top.equalToSuperview().offset(160)
            make.size.equalTo(146)
        }

        addLabel(
            text: "RECHARGE",
            x: 160,
            y: 207,
            font: KivroTypography.inter(size: 32, weight: .bold)
        )
        configureLabel(
            coinBalanceLabel,
            text: "",
            x: 200,
            y: 250,
            font: KivroTypography.inter(size: 14, weight: .bold)
        )
    }

    private func configureActions() {
        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("Settings", for: .normal)
        settingsButton.setTitleColor(
            UIColor(red: 224 / 255, green: 216 / 255, blue: 239 / 255, alpha: 1),
            for: .normal
        )
        settingsButton.titleLabel?.font = KivroTypography.inter(size: 18, weight: .bold)
        settingsButton.backgroundColor = .clear
        settingsButton.layer.cornerRadius = 16
        settingsButton.layer.borderWidth = 2
        settingsButton.layer.borderColor = UIColor(
            red: 224 / 255,
            green: 216 / 255,
            blue: 239 / 255,
            alpha: 1
        ).cgColor
        settingsButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
        contentView.addSubview(settingsButton)
        settingsButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(21)
            make.trailing.equalTo(contentView.snp.centerX).offset(-10)
            make.top.equalToSuperview().offset(311)
            make.height.equalTo(54)
        }

        let editButton = KivroProfileEditButton()
        editButton.setTitle("Edit Profile", for: .normal)
        editButton.addTarget(self, action: #selector(showEditProfile), for: .touchUpInside)
        contentView.addSubview(editButton)
        editButton.snp.makeConstraints { make in
            make.leading.equalTo(contentView.snp.centerX).offset(10)
            make.trailing.equalToSuperview().inset(21)
            make.top.equalToSuperview().offset(311)
            make.height.equalTo(54)
        }

        addLabel(
            text: "WORK",
            x: 21,
            y: 379,
            font: KivroTypography.inter(size: 22, weight: .heavy, italic: true)
        )
    }

    private func configureWorkList() {
        workCollectionView.backgroundColor = .clear
        workCollectionView.alwaysBounceVertical = true
        workCollectionView.showsVerticalScrollIndicator = false
        workCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        workCollectionView.dataSource = self
        workCollectionView.delegate = self
        workCollectionView.register(
            FeedPostCell.self,
            forCellWithReuseIdentifier: FeedPostCell.reuseIdentifier
        )
        contentView.addSubview(workCollectionView)
        workCollectionView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(422)
            make.leading.trailing.equalToSuperview().inset(21)
            make.bottom.equalTo(contentView.safeAreaLayoutGuide.snp.bottom)
        }

        emptyWorkLabel.text = "No work yet."
        emptyWorkLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        emptyWorkLabel.font = KivroTypography.inter(size: 16, weight: .medium)
        emptyWorkLabel.textAlignment = .center
        emptyWorkLabel.isUserInteractionEnabled = false
        contentView.addSubview(emptyWorkLabel)
        emptyWorkLabel.snp.makeConstraints { make in
            make.centerX.equalTo(workCollectionView)
            make.top.equalTo(workCollectionView).offset(54)
        }
    }

    private func refreshProfile() {
        let profileState = KivroProfileState.shared
        profileAvatarView.image = profileState.resolvedAvatar(for: currentUserIdentifier)
            ?? UIImage(named: "kivro_profile_header_avatar")
        profileNameLabel.text = profileState.resolvedName(for: currentUserIdentifier)

        let socialCounts = KivroSeedDatabase.shared.socialCounts(for: currentUserIdentifier)
        followingCountLabel.text = Self.compactCount(socialCounts.following)
        followerCountLabel.text = Self.compactCount(socialCounts.followers)
        let balance = KivroCoinWallet.shared.balance(for: currentUserIdentifier)
        coinBalanceLabel.text = String(
            format: KivroStrings.value("profile.balance_format"),
            balance
        )

        posts = currentUserPosts
        emptyWorkLabel.isHidden = !posts.isEmpty
        workCollectionView.reloadData()
    }

    private var currentUserPosts: [PostPreview] {
        let localPosts = KivroPostStore.shared.posts
            .filter { $0.authorIdentifier == currentUserIdentifier }
            .map { post in
                let counts = KivroSeedDatabase.shared.engagementCounts(
                    postIdentifier: post.identifier.uuidString.lowercased()
                )
                return post.updatingEngagement(
                    likeCount: counts.likes,
                    commentCount: counts.comments
                )
            }
        let storedPosts = KivroSeedDatabase.shared.posts(authorIdentifier: currentUserIdentifier).map { post in
            PostPreview(
                identifier: UUID(uuidString: post.identifier) ?? UUID(),
                authorIdentifier: currentUserIdentifier,
                authorName: KivroProfileState.shared.resolvedName(for: currentUserIdentifier),
                avatarAssetName: KivroProfileState.shared.resolvedAvatarAssetName(for: currentUserIdentifier),
                avatarImage: KivroProfileState.shared.resolvedAvatar(for: currentUserIdentifier),
                bodyText: post.body,
                mediaAssetNames: [post.mediaAssetName],
                videoURL: post.isVideo
                    ? KivroVideoMedia.shared.bundledURL(resourceName: post.mediaAssetName)
                    : nil,
                category: post.category,
                likeCount: post.likeCount,
                commentCount: post.commentCount,
                isVideo: post.isVideo
            )
        }
        return localPosts + storedPosts
    }

    private func makeWorkLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 28
        layout.sectionInset = .zero
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        posts.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeedPostCell.reuseIdentifier,
            for: indexPath
        )
        guard let postCell = cell as? FeedPostCell else { return cell }
        let post = posts[indexPath.item]
        let postIdentifier = post.identifier.uuidString.lowercased()
        let isLiked = KivroSeedDatabase.shared.isPostLiked(
            postIdentifier: postIdentifier,
            userIdentifier: currentUserIdentifier
        )
        postCell.configure(with: post, isLiked: isLiked)
        postCell.onComments = { [weak self] in
            self?.present(CommentsViewController(postIdentifier: post.identifier), animated: true)
        }
        postCell.onMedia = { [weak self] mediaIndex in
            guard let self else { return }
            if post.isVideo {
                guard let videoURL = post.videoURL else { return }
                navigationController?.pushViewController(
                    KivroVideoPlayerViewController(videoURL: videoURL),
                    animated: true
                )
                return
            }
            let images = post.displayedImages
            guard images.indices.contains(mediaIndex) else { return }
            navigationController?.pushViewController(
                KivroImagePreviewViewController(image: images[mediaIndex]),
                animated: true
            )
        }
        postCell.onLikeChange = { [weak self] requestedState in
            guard let self, KivroAccountAccess.requireAccount(from: self) else { return nil }
            do {
                return try KivroSeedDatabase.shared.setPostLiked(
                    requestedState,
                    postIdentifier: postIdentifier,
                    userIdentifier: currentUserIdentifier
                )
            } catch {
                KivroToastPresenter.show(message: "Unable to update this like.", in: view)
                return nil
            }
        }
        return postCell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let post = posts[indexPath.item]
        return CGSize(
            width: collectionView.bounds.width,
            height: FeedPostCell.preferredHeight(forMediaCount: post.displayedMediaCount)
        )
    }

    @discardableResult
    private func addLabel(
        text: String,
        x: CGFloat,
        y: CGFloat,
        font: UIFont,
        alpha: CGFloat = 1
    ) -> UILabel {
        let label = UILabel()
        configureLabel(label, text: text, x: x, y: y, font: font, alpha: alpha)
        return label
    }

    private func configureLabel(
        _ label: UILabel,
        text: String,
        x: CGFloat,
        y: CGFloat,
        font: UIFont,
        alpha: CGFloat = 1
    ) {
        label.text = text
        label.textColor = UIColor.white.withAlphaComponent(alpha)
        label.font = font
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(x)
            make.top.equalToSuperview().offset(y)
        }
    }

    private static func compactCount(_ count: Int) -> String {
        guard count >= 1_000 else { return String(count) }
        return String(format: "%.1f K", Double(count) / 1_000)
    }

    @objc private func showSettings() {
        navigationController?.pushViewController(SettingsViewController(), animated: true)
    }

    @objc private func showFollowing() {
        navigationController?.pushViewController(UserListViewController(mode: .following), animated: true)
    }

    @objc private func showFollowers() {
        navigationController?.pushViewController(UserListViewController(mode: .followers), animated: true)
    }

    @objc private func showEditProfile() {
        navigationController?.pushViewController(EditProfileViewController(), animated: true)
    }

    @objc private func showRecharge() {
        navigationController?.pushViewController(RechargeViewController(), animated: true)
    }

    @objc private func profileDataDidChange() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.refreshProfile() }
            return
        }
        refreshProfile()
    }
}
