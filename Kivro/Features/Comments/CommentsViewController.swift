import UIKit
import SnapKit

final class CommentsViewController: KivroViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let postIdentifier: UUID
    private let sheet = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let inputField = UITextField()
    private var inputBottomConstraint: Constraint?
    private var isSending = false
    private var comments: [CommentPreview] = []

    init(postIdentifier: UUID? = nil) {
        self.postIdentifier = postIdentifier
            ?? KivroSeedDatabase.shared.posts().first.flatMap { UUID(uuidString: $0.identifier) }
            ?? UUID()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        reloadComments()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(blockStateDidChange),
            name: .kivroBlockStateDidChange,
            object: nil
        )
    }

    private func reloadComments() {
        comments = KivroSeedDatabase.shared.comments(
            postIdentifier: postIdentifier.uuidString.lowercased()
        )
        .filter {
            !KivroSeedDatabase.shared.isBlocked(
                sourceIdentifier: currentUserIdentifier,
                targetIdentifier: $0.authorIdentifier
            )
        }
        .map(CommentPreview.init(storedComment:))
        tableView.reloadData()
    }

    @objc private func blockStateDidChange() {
        reloadComments()
    }

    private func configureLayout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.64)

        let dismissArea = UIControl()
        dismissArea.backgroundColor = .clear
        dismissArea.accessibilityLabel = "Close comments"
        dismissArea.addTarget(self, action: #selector(dismissComments), for: .touchUpInside)
        view.addSubview(dismissArea)

        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 22
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(330)
            make.bottom.equalToSuperview()
        }
        dismissArea.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(sheet.snp.top)
        }

        let title = UILabel()
        title.text = "Comment"
        title.textColor = .black
        title.font = KivroTypography.inter(size: 24, weight: .heavy, italic: true)
        sheet.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(23)
            make.top.equalToSuperview().offset(19)
        }

        inputBar.backgroundColor = .white
        view.addSubview(inputBar)
        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(74)
            inputBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.keyboardDismissMode = .interactive
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 104
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseIdentifier)
        sheet.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(58)
            make.bottom.equalToSuperview().inset(74)
        }

        let compose = UIImageView(image: UIImage(named: "kivro_compose_icon"))
        compose.contentMode = .scaleAspectFit
        inputBar.addSubview(compose)
        compose.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(13)
            make.top.equalToSuperview().offset(21)
            make.size.equalTo(21)
        }

        inputField.placeholder = "Say something..."
        inputField.textColor = .black
        inputField.font = KivroTypography.inter(size: 14, weight: .regular)
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputBar.addSubview(inputField)
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(44)
            make.top.equalToSuperview().offset(15)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(36)
        }

        let indicator = UIView()
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = 2.5
        inputBar.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        comments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseIdentifier, for: indexPath)
        guard let commentCell = cell as? CommentCell else { return cell }
        let comment = comments[indexPath.row]
        commentCell.configure(with: comment, currentUserIdentifier: currentUserIdentifier)
        commentCell.onMore = { [weak self] in
            guard let self,
                  comment.authorIdentifier != currentUserIdentifier else { return }
            present(
                MoreActionsViewController(
                    targetUserIdentifier: comment.authorIdentifier,
                    currentUserIdentifier: currentUserIdentifier
                ),
                animated: true
            )
        }
        commentCell.onAvatar = { [weak self] in
            guard let self,
                  comment.authorIdentifier != currentUserIdentifier,
                  KivroSeedDatabase.shared.user(identifier: comment.authorIdentifier) != nil else { return }
            showCreatorProfile(identifier: comment.authorIdentifier)
        }
        return commentCell
    }

    private func showCreatorProfile(identifier: String) {
        let presenter = presentingViewController
        let navigationController: UINavigationController?
        if let navigation = presenter as? UINavigationController {
            navigationController = navigation
        } else if let tabBarController = presenter as? UITabBarController {
            navigationController = tabBarController.selectedViewController as? UINavigationController
        } else {
            navigationController = presenter?.navigationController
        }
        dismiss(animated: true) { [currentUserIdentifier] in
            navigationController?.pushViewController(
                CreatorProfileViewController(
                    creatorIdentifier: identifier,
                    currentUserIdentifier: currentUserIdentifier
                ),
                animated: true
            )
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendComment()
        return false
    }

    private func sendComment() {
        guard !isSending else { return }
        guard let value = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return }
        isSending = true
        defer { isSending = false }
        do {
            let storedComment = try KivroSeedDatabase.shared.addComment(
                postIdentifier: postIdentifier.uuidString.lowercased(),
                authorIdentifier: currentUserIdentifier,
                authorName: KivroProfileState.shared.resolvedName(for: currentUserIdentifier),
                avatarAssetName: KivroProfileState.shared.resolvedAvatarAssetName(for: currentUserIdentifier),
                body: value
            )
            comments.append(CommentPreview(storedComment: storedComment))
        } catch {
            KivroToastPresenter.show(message: "Unable to post this comment.", in: view)
            return
        }
        let indexPath = IndexPath(row: comments.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
        inputField.text = nil
        inputField.resignFirstResponder()
        DispatchQueue.main.async { [weak self] in
            self?.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    @objc private func dismissComments() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        inputBottomConstraint?.update(offset: -overlap)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16)
        ) {
            self.view.layoutIfNeeded()
        }
    }
}
