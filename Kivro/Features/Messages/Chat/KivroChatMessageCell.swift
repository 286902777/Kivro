import UIKit
import SnapKit

final class KivroChatMessageCell: UITableViewCell {
    static let reuseIdentifier = "KivroChatMessageCell"

    var onAvatar: (() -> Void)?

    private let avatarView = UIImageView()
    private let avatarButton = UIButton(type: .custom)
    private let bubbleView = UIView()
    private var waveformView: UIImageView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        waveformView?.layer.removeAllAnimations()
        waveformView = nil
        bubbleView.subviews.forEach { $0.removeFromSuperview() }
        onAvatar = nil
    }

    func configure(with message: KivroChatMessage, isPlaying: Bool) {
        bubbleView.subviews.forEach { $0.removeFromSuperview() }
        waveformView?.layer.removeAllAnimations()
        waveformView = nil

        let isCurrentUser = message.sender == .currentUser
        avatarView.image = KivroProfileState.shared.resolvedAvatar(for: message.senderIdentifier)
            ?? UIImage(named: "kivro_profile_header_avatar")
        let centersBubbleVertically: Bool
        if case .voice = message.content {
            centersBubbleVertically = true
        } else {
            centersBubbleVertically = false
        }
        configurePosition(
            isCurrentUser: isCurrentUser,
            centersBubbleVertically: centersBubbleVertically
        )
        avatarButton.isHidden = isCurrentUser
        avatarButton.accessibilityLabel = isCurrentUser ? nil : "Open user profile"

        switch message.content {
        case .text(let text):
            configureText(text)
        case .image(let image):
            configureImage(image)
        case .voice(_, let duration, _):
            configureVoice(duration: duration, isPlaying: isPlaying)
        }
    }

    private func configureView() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 27
        contentView.addSubview(avatarView)

        avatarButton.addTarget(self, action: #selector(openAvatar), for: .touchUpInside)
        contentView.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.edges.equalTo(avatarView)
        }

        bubbleView.clipsToBounds = true
        contentView.addSubview(bubbleView)
    }

    @objc private func openAvatar() {
        onAvatar?()
    }

    private func configurePosition(isCurrentUser: Bool, centersBubbleVertically: Bool) {
        avatarView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.size.equalTo(54)
            make.bottom.lessThanOrEqualToSuperview().inset(6)
            make.bottom.equalToSuperview().inset(6).priority(.high)
            if isCurrentUser {
                make.trailing.equalToSuperview().inset(16)
            } else {
                make.leading.equalToSuperview().offset(16)
            }
        }

        bubbleView.snp.remakeConstraints { make in
            if centersBubbleVertically {
                make.centerY.equalTo(avatarView)
                make.top.greaterThanOrEqualToSuperview().offset(6)
            } else {
                make.top.equalToSuperview().offset(6)
                make.bottom.equalToSuperview().inset(6).priority(.medium)
            }
            make.bottom.lessThanOrEqualToSuperview().inset(6)
            if isCurrentUser {
                make.trailing.equalTo(avatarView.snp.leading).offset(-11)
            } else {
                make.leading.equalTo(avatarView.snp.trailing).offset(10)
            }
        }
    }

    private func configureText(_ text: String) {
        bubbleView.backgroundColor = .white
        bubbleView.layer.cornerRadius = 12

        let label = UILabel()
        label.text = text
        label.textColor = .black
        label.font = KivroTypography.inter(size: 13, weight: .regular)
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = 208
        bubbleView.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 9, left: 11, bottom: 9, right: 10)
            )
            make.width.lessThanOrEqualTo(208)
        }
    }

    private func configureImage(_ image: UIImage) {
        bubbleView.backgroundColor = .clear
        bubbleView.layer.cornerRadius = 14

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        bubbleView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(121)
        }
    }

    private func configureVoice(duration: TimeInterval, isPlaying: Bool) {
        bubbleView.backgroundColor = .white
        bubbleView.layer.cornerRadius = 10

        let waveform = UIImageView(image: UIImage(named: "kivro_chat_waveform"))
        waveform.contentMode = .scaleAspectFit
        bubbleView.addSubview(waveform)
        waveform.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(92)
            make.height.equalTo(22)
        }
        waveformView = waveform

        let durationLabel = UILabel()
        durationLabel.text = "\(max(1, Int(duration.rounded())))′"
        durationLabel.textColor = .black
        durationLabel.font = KivroTypography.inter(size: 14, weight: .bold)
        bubbleView.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }

        bubbleView.snp.makeConstraints { make in
            make.width.equalTo(150)
            make.height.equalTo(39)
        }

        if isPlaying {
            animateWaveform(waveform)
        }
    }

    private func animateWaveform(_ waveform: UIImageView) {
        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            options: [.autoreverse, .repeat, .allowUserInteraction]
        ) {
            waveform.alpha = 0.3
            waveform.transform = CGAffineTransform(scaleX: 0.96, y: 1.15)
        }
    }
}
