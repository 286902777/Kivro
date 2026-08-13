import UIKit
import SnapKit

final class MessagePreviewCell: UITableViewCell {
    static let reuseIdentifier = "MessagePreviewCell"
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureLayout()
    }

    func configure(with preview: MessagePreview) {
        avatarView.image = UIImage(named: preview.avatarName)
        nameLabel.text = preview.name
        messageLabel.text = preview.message
        timeLabel.text = preview.displayedTime
    }

    private func configureLayout() {
        backgroundColor = .clear
        selectionStyle = .none
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 27
        nameLabel.textColor = .white
        nameLabel.font = KivroTypography.inter(size: 18, weight: .bold)
        messageLabel.textColor = .white
        messageLabel.font = KivroTypography.inter(size: 12, weight: .bold)
        messageLabel.numberOfLines = 2
        timeLabel.textColor = .white
        timeLabel.font = KivroTypography.inter(size: 12, weight: .bold)
        [avatarView, nameLabel, messageLabel, timeLabel].forEach(contentView.addSubview)
        avatarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(9)
            make.size.equalTo(54)
        }
        nameLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.top.equalTo(avatarView).offset(2)
        }
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(17)
        }
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.lessThanOrEqualToSuperview().inset(18)
            make.top.equalTo(nameLabel.snp.bottom).offset(9)
        }
    }
}
