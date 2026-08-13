import UIKit
import SnapKit

final class CommentCell: UITableViewCell {
    static let reuseIdentifier = "CommentCell"

    var onMore: (() -> Void)?
    var onAvatar: (() -> Void)?

    private let avatarView = UIImageView()
    private let authorLabel = UILabel()
    private let bodyLabel = UILabel()
    private let moreButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureViews()
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    func configure(with comment: CommentPreview, currentUserIdentifier: String) {
        avatarView.image = KivroProfileState.shared.resolvedAvatar(for: comment.authorIdentifier)
            ?? UIImage(named: comment.avatarAssetName)
        let resolvedName = KivroProfileState.shared.resolvedName(for: comment.authorIdentifier)
        authorLabel.text = resolvedName == "User" ? comment.authorName : resolvedName
        bodyLabel.text = comment.body
        moreButton.isHidden = comment.authorIdentifier == currentUserIdentifier
    }

    private func configureViews() {
        backgroundColor = .clear
        selectionStyle = .none

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 26
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(showAuthor))
        )

        authorLabel.textColor = .black
        authorLabel.font = KivroTypography.inter(size: 16, weight: .bold)

        bodyLabel.textColor = .black
        bodyLabel.font = KivroTypography.inter(size: 11, weight: .medium)
        bodyLabel.numberOfLines = 0

        moreButton.setTitle("··· More", for: .normal)
        moreButton.setTitleColor(UIColor.black.withAlphaComponent(0.45), for: .normal)
        moreButton.titleLabel?.font = KivroTypography.inter(size: 9, weight: .regular)
        moreButton.contentHorizontalAlignment = .left
        moreButton.addTarget(self, action: #selector(showMore), for: .touchUpInside)

        [avatarView, authorLabel, bodyLabel, moreButton].forEach(contentView.addSubview)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(23)
            make.top.equalToSuperview().offset(8)
            make.size.equalTo(52)
        }
        authorLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(11)
            make.top.equalTo(avatarView).offset(2)
            make.trailing.lessThanOrEqualToSuperview().inset(20)
        }
        bodyLabel.snp.makeConstraints { make in
            make.leading.equalTo(authorLabel)
            make.top.equalTo(authorLabel.snp.bottom).offset(5)
            make.trailing.equalToSuperview().inset(23)
        }
        moreButton.snp.makeConstraints { make in
            make.leading.equalTo(authorLabel)
            make.top.equalTo(bodyLabel.snp.bottom).offset(7)
            make.width.equalTo(72)
            make.height.equalTo(24)
            make.bottom.equalToSuperview().inset(10)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onMore = nil
        onAvatar = nil
    }

    @objc private func showMore() {
        guard !moreButton.isHidden else { return }
        onMore?()
    }

    @objc private func showAuthor() {
        onAvatar?()
    }
}
