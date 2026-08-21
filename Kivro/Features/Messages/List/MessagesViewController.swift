import UIKit
import SnapKit

final class MessagesViewController: KivroViewController, UITableViewDataSource, UITableViewDelegate {
    private let contentView = UIView()
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private var messages: [MessagePreview] = []
    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let background = KivroGradientView()
        view.insertSubview(background, at: 0)
        background.snp.makeConstraints { make in make.edges.equalToSuperview() }

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
            make.width.equalToSuperview().priority(.high)
            make.width.lessThanOrEqualTo(600)
        }

        let titleLabel = UILabel()
        titleLabel.text = KivroStrings.value("messages.title")
        titleLabel.textColor = .white
        titleLabel.font = KivroTypography.inter(size: 40, weight: .heavy, italic: true)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.equalToSuperview().offset(21)
            make.height.equalTo(48)
        }
        let underline = KivroFeedSelectionUnderlineView()
        contentView.addSubview(underline)
        underline.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(30)
            make.top.equalToSuperview().offset(109)
            make.width.equalTo(20)
            make.height.equalTo(7)
        }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MessagePreviewCell.self, forCellReuseIdentifier: MessagePreviewCell.reuseIdentifier)
        contentView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(137)
            make.leading.trailing.bottom.equalToSuperview()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadMessages),
            name: .kivroChatMessagesDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadMessages),
            name: .kivroFollowStateDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reloadMessages),
            name: .kivroBlockStateDidChange,
            object: nil
        )
        reloadMessages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        reloadMessages()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MessagePreviewCell.reuseIdentifier, for: indexPath) as? MessagePreviewCell else {
            return UITableViewCell()
        }
        cell.configure(with: messages[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard messages.indices.contains(indexPath.row) else { return }
        let preview = messages[indexPath.row]
        navigationController?.pushViewController(
            ChatViewController(targetUserIdentifier: preview.userIdentifier),
            animated: true
        )
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        84
    }

    @objc private func reloadMessages() {
        messages = KivroSeedDatabase.shared.conversationPreviews(for: currentUserIdentifier).map {
            MessagePreview(
                userIdentifier: $0.user.identifier,
                name: $0.user.username,
                message: $0.lastMessage,
                avatarName: $0.user.avatarAssetName,
                updatedAt: $0.updatedAt
            )
        }
        tableView.reloadData()
    }
}
