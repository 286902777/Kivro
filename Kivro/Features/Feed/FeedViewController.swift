import UIKit
import SnapKit

final class FeedViewController: KivroViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let showsVideo: Bool
    private let categories = ["For You", "Gothic", "Cyber", "Fantasy", "Mecha", "Period"]
    private let horizontalInset: CGFloat = 21
    private var selectedCategory = "For You"
    private var categoryButtons: [UIButton] = []
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private var didPresentQAComments = false

    private var seededPosts: [PostPreview] {
        KivroSeedDatabase.shared.posts().map { post in
            let user = KivroSeedDatabase.shared.user(identifier: post.authorIdentifier)
            return PostPreview(
                identifier: UUID(uuidString: post.identifier) ?? UUID(),
                authorIdentifier: post.authorIdentifier,
                authorName: user?.username
                    ?? KivroProfileState.shared.resolvedName(for: post.authorIdentifier),
                avatarAssetName: user?.avatarAssetName
                    ?? KivroProfileState.shared.resolvedAvatarAssetName(for: post.authorIdentifier),
                avatarImage: KivroProfileState.shared.resolvedAvatar(for: post.authorIdentifier),
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
    }

    private var filteredPosts: [PostPreview] {
        let localPosts = KivroPostStore.shared.posts.map { post in
            let counts = KivroSeedDatabase.shared.engagementCounts(
                postIdentifier: post.identifier.uuidString.lowercased()
            )
            return post.updatingEngagement(
                likeCount: counts.likes,
                commentCount: counts.comments
            )
        }
        let allPosts = (localPosts + seededPosts).filter {
            !KivroSeedDatabase.shared.isBlocked(
                sourceIdentifier: currentUserIdentifier,
                targetIdentifier: $0.authorIdentifier
            )
        }
        let contentPosts = showsVideo ? allPosts.filter(\.isVideo) : allPosts
        guard selectedCategory != "For You" else { return contentPosts }
        return contentPosts.filter { $0.category == selectedCategory }
    }

    init(showsVideo: Bool = false) {
        self.showsVideo = showsVideo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(postStoreDidChange),
            name: .kivroPostStoreDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(engagementDidChange),
            name: .kivroPostEngagementDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(blockStateDidChange),
            name: .kivroBlockStateDidChange,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        collectionView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if DEBUG
        guard ProcessInfo.processInfo.environment["KIVRO_QA_SCREEN"] == "comments",
              !didPresentQAComments else { return }
        didPresentQAComments = true
        guard let post = filteredPosts.first else { return }
        present(CommentsViewController(postIdentifier: post.identifier), animated: false)
#endif
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { make in make.edges.equalToSuperview() }

        let categoryScroll = UIScrollView()
        categoryScroll.showsHorizontalScrollIndicator = false
        view.addSubview(categoryScroll)
        categoryScroll.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(horizontalInset)
            make.trailing.equalToSuperview().inset(120)
            make.top.equalToSuperview().offset(58)
            make.height.equalTo(55)
        }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 14
        stack.alignment = .top
        categoryScroll.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        categoryButtons = categories.enumerated().map { index, category in
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(category, for: .normal)
            button.titleLabel?.font = KivroTypography.inter(
                size: category == "For You" ? 26 : 17,
                weight: .heavy,
                italic: true
            )
            button.addTarget(self, action: #selector(selectCategory(_:)), for: .touchUpInside)
            button.snp.makeConstraints { make in make.height.equalTo(44) }
            stack.addArrangedSubview(button)
            return button
        }
        updateCategoryAppearance()

        let release = UIButton(type: .system)
        release.setTitle("+ Release", for: .normal)
        release.setTitleColor(.white, for: .normal)
        release.titleLabel?.font = KivroTypography.inter(size: 13, weight: .heavy, italic: true)
        release.layer.borderColor = UIColor.white.cgColor
        release.layer.borderWidth = 2
        release.layer.cornerRadius = 20
        release.addTarget(self, action: #selector(showComposer), for: .touchUpInside)
        view.addSubview(release)
        release.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(61)
            make.width.equalTo(92)
            make.height.equalTo(40)
        }

        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        collectionView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 16, right: 0)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FeedPostCell.self, forCellWithReuseIdentifier: FeedPostCell.reuseIdentifier)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(horizontalInset)
            make.top.equalToSuperview().offset(132)
            make.bottom.equalToSuperview()
        }
    }

    private func updateCategoryAppearance() {
        for (index, button) in categoryButtons.enumerated() {
            let selected = categories[index] == selectedCategory
            button.setTitleColor(UIColor.white.withAlphaComponent(selected ? 1 : 0.4), for: .normal)
            button.layer.sublayers?.removeAll(where: { $0.name == "selection" })
            guard selected else { continue }
            let line = CAShapeLayer()
            line.name = "selection"
            line.strokeColor = UIColor.white.cgColor
            line.fillColor = UIColor.clear.cgColor
            line.lineWidth = 4
            line.lineCap = .round
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 12, y: 40))
            path.addQuadCurve(to: CGPoint(x: 38, y: 40), controlPoint: CGPoint(x: 25, y: 49))
            line.path = path.cgPath
            button.layer.addSublayer(line)
        }
    }

    private func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 28
        layout.sectionInset = .zero
        return layout
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredPosts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedPostCell.reuseIdentifier, for: indexPath)
        guard let postCell = cell as? FeedPostCell else { return cell }
        let post = filteredPosts[indexPath.item]
        let isLiked = KivroSeedDatabase.shared.isPostLiked(
            postIdentifier: post.identifier.uuidString.lowercased(),
            userIdentifier: currentUserIdentifier
        )
        postCell.configure(with: post, isLiked: isLiked)
        postCell.onComments = { [weak self] in
            guard let self, KivroAccountAccess.requireAccount(from: self) else { return }
            present(CommentsViewController(postIdentifier: post.identifier), animated: true)
        }
        postCell.onAvatar = { [weak self] in
            guard let self, KivroAccountAccess.requireAccount(from: self) else { return }
            guard post.authorIdentifier != currentUserIdentifier,
                  KivroSeedDatabase.shared.user(identifier: post.authorIdentifier) != nil else { return }
            navigationController?.pushViewController(
                CreatorProfileViewController(
                    creatorIdentifier: post.authorIdentifier,
                    currentUserIdentifier: currentUserIdentifier
                ),
                animated: true
            )
        }
        postCell.onMedia = { [weak self] mediaIndex in
            guard let self else { return }
            if post.isVideo {
                guard let videoURL = post.videoURL else {
                    KivroToastPresenter.show(message: "Video unavailable.", in: view)
                    return
                }
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
                    postIdentifier: post.identifier.uuidString.lowercased(),
                    userIdentifier: currentUserIdentifier
                )
            } catch {
                KivroToastPresenter.show(message: "Unable to update this like.", in: view)
                return nil
            }
        }
        postCell.onMore = { [weak self] in
            guard let self, KivroAccountAccess.requireAccount(from: self) else { return }
            guard post.authorIdentifier != currentUserIdentifier else { return }
            present(
                MoreActionsViewController(
                    targetUserIdentifier: post.authorIdentifier,
                    currentUserIdentifier: currentUserIdentifier
                ),
                animated: true
            )
        }
        return postCell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let post = filteredPosts[indexPath.item]
        let width = collectionView.bounds.width
        let height = FeedPostCell.preferredHeight(forMediaCount: post.displayedMediaCount)
        return CGSize(width: width, height: height)
    }

    @objc private func selectCategory(_ sender: UIButton) {
        selectedCategory = categories[sender.tag]
        updateCategoryAppearance()
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    @objc private func blockStateDidChange() {
        collectionView.reloadData()
    }

    @objc private func postStoreDidChange() {
        selectedCategory = "For You"
        updateCategoryAppearance()
        collectionView.reloadData()
    }

    @objc private func engagementDidChange() {
        collectionView.reloadData()
    }

    @objc private func showComposer() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        navigationController?.pushViewController(PostComposerViewController(), animated: true)
    }
}
