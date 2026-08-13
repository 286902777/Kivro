import UIKit
import SnapKit

final class UserListViewController: KivroViewController {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let mode: UserListMode
    private let contentStack = UIStackView()
    private var users: [KivroStoredUser] = []

    init(mode: UserListMode) {
        self.mode = mode
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
            selector: #selector(relationshipsDidChange),
            name: .kivroFollowStateDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(relationshipsDidChange),
            name: .kivroBlockStateDidChange,
            object: nil
        )
        reloadUsers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        reloadUsers()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = KivroPageHeaderView(title: KivroStrings.value(mode.titleKey))
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentStack.axis = .vertical
        contentStack.spacing = 0
        scrollView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func reloadUsers() {
        let database = KivroSeedDatabase.shared
        switch mode {
        case .following:
            users = database.followingUsers(for: currentUserIdentifier)
        case .followers:
            users = database.followerUsers(for: currentUserIdentifier)
        case .blacklist:
            users = database.blockedUsers(for: currentUserIdentifier)
        }

        contentStack.arrangedSubviews.forEach { view in
            contentStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        if users.isEmpty {
            contentStack.addArrangedSubview(makeEmptyView())
        } else {
            users.enumerated().forEach { index, user in
                contentStack.addArrangedSubview(makeUserRow(user, index: index))
            }
        }
    }

    private func makeUserRow(_ user: KivroStoredUser, index: Int) -> UIView {
        let row = UIView()
        row.snp.makeConstraints { make in make.height.equalTo(88) }

        let avatar = UIImageView(
            image: KivroProfileState.shared.resolvedAvatar(for: user.identifier)
                ?? UIImage(named: user.avatarAssetName)
        )
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 26
        row.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.top.equalToSuperview().offset(23)
            make.size.equalTo(52)
        }

        let name = UILabel()
        name.text = KivroProfileState.shared.resolvedName(for: user.identifier)
        name.textColor = .white
        name.font = KivroTypography.inter(size: 22, weight: .bold)
        row.addSubview(name)
        name.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(86)
            make.centerY.equalTo(avatar)
            make.trailing.lessThanOrEqualToSuperview().inset(72)
        }

        let actionButton = UIButton(type: .system)
        actionButton.tag = index
        configureActionButton(actionButton, for: user)
        actionButton.tintColor = .white
        actionButton.layer.cornerRadius = 20
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = UIColor.white.cgColor
        actionButton.addTarget(self, action: #selector(handleUserAction(_:)), for: .touchUpInside)
        row.addSubview(actionButton)
        actionButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(17)
            make.centerY.equalTo(avatar)
            make.size.equalTo(40)
        }
        return row
    }

    private func configureActionButton(_ button: UIButton, for user: KivroStoredUser) {
        let isAlreadyFollowing = KivroSeedDatabase.shared.isFollowing(
            sourceIdentifier: currentUserIdentifier,
            targetIdentifier: user.identifier
        )
        let symbolName: String
        switch mode {
        case .followers where isAlreadyFollowing:
            symbolName = "checkmark"
            button.isEnabled = false
            button.accessibilityLabel = "Following"
        case .followers:
            symbolName = "plus"
            button.accessibilityLabel = "Follow"
        case .following:
            symbolName = "minus"
            button.accessibilityLabel = "Unfollow"
        case .blacklist:
            symbolName = "minus"
            button.accessibilityLabel = "Unblock"
        }
        let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: .bold)
        button.setImage(UIImage(systemName: symbolName, withConfiguration: configuration), for: .normal)
    }

    private func makeEmptyView() -> UIView {
        let container = UIView()
        container.snp.makeConstraints { make in make.height.equalTo(180) }
        let label = UILabel()
        label.text = KivroStrings.value("social.empty")
        label.textColor = UIColor.white.withAlphaComponent(0.55)
        label.font = KivroTypography.inter(size: 16, weight: .medium)
        label.textAlignment = .center
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(54)
        }
        return container
    }

    @objc private func handleUserAction(_ sender: UIButton) {
        guard users.indices.contains(sender.tag) else { return }
        let target = users[sender.tag]
        do {
            switch mode {
            case .following:
                try KivroSeedDatabase.shared.setFollowing(
                    false,
                    sourceIdentifier: currentUserIdentifier,
                    targetIdentifier: target.identifier
                )
                KivroToastPresenter.show(message: KivroStrings.value("social.unfollowed"), in: view)
            case .followers:
                try KivroSeedDatabase.shared.setFollowing(
                    true,
                    sourceIdentifier: currentUserIdentifier,
                    targetIdentifier: target.identifier
                )
                KivroToastPresenter.show(message: KivroStrings.value("social.followed"), in: view)
            case .blacklist:
                try KivroSeedDatabase.shared.setBlocked(
                    false,
                    sourceIdentifier: currentUserIdentifier,
                    targetIdentifier: target.identifier
                )
                KivroToastPresenter.show(message: KivroStrings.value("social.unblocked"), in: view)
            }
            reloadUsers()
        } catch {
            KivroToastPresenter.show(message: KivroStrings.value("social.update_failed"), in: view)
        }
    }

    @objc private func relationshipsDidChange() {
        reloadUsers()
    }
}
