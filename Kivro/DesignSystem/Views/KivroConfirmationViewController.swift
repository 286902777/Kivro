import UIKit
import SnapKit

final class KivroConfirmationViewController: UIViewController {
    private enum Layout {
        static let horizontalInset: CGFloat = 19
        static let cardWidth: CGFloat = 336
        static let compactTop: CGFloat = 291
        static let compactHeight: CGFloat = 230
        static let largeTop: CGFloat = 53
        static let largeHeight: CGFloat = 728
        static let buttonWidth: CGFloat = 140
        static let buttonHeight: CGFloat = 44
    }

    private let titleKey: String
    private let messageKey: String
    private let confirmKey: String
    private let isDestructive: Bool
    private let onConfirm: () -> Void
    var onCancel: (() -> Void)?

    init(
        titleKey: String,
        messageKey: String,
        confirmKey: String,
        isDestructive: Bool = false,
        onConfirm: @escaping () -> Void
    ) {
        self.titleKey = titleKey
        self.messageKey = messageKey
        self.confirmKey = confirmKey
        self.isDestructive = isDestructive
        self.onConfirm = onConfirm
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        if titleKey == "prompt.agreement.title" {
            configureLargeDialog()
        } else {
            configureCompactDialog()
        }
    }

    private func configureCompactDialog() {
        let card = makeBackgroundView(imageName: "kivro_dialog_background_compact")
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.top.equalToSuperview().offset(Layout.compactTop)
            make.height.equalTo(Layout.compactHeight)
        }

        let titleLabel = makeTitleLabel(text: KivroStrings.value(titleKey))
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(30)
            make.height.equalTo(42)
        }

        let messageLabel = UILabel()
        messageLabel.text = KivroStrings.value(messageKey)
        messageLabel.textColor = UIColor(red: 28 / 255, green: 20 / 255, blue: 34 / 255, alpha: 1)
        messageLabel.font = KivroTypography.inter(size: 18, weight: .semibold)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 4
        messageLabel.adjustsFontSizeToFitWidth = true
        messageLabel.minimumScaleFactor = 0.82
        card.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalTo(titleLabel.snp.bottom).offset(1)
            make.bottom.lessThanOrEqualToSuperview().inset(69)
        }

        addActions(to: card, top: 167)
    }

    private func configureLargeDialog() {
        let card = makeBackgroundView(imageName: "kivro_dialog_background_large")
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.top.equalToSuperview().offset(Layout.largeTop)
            make.height.equalTo(Layout.largeHeight)
        }

        let titleLabel = makeTitleLabel(text: "EULA")
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(31)
            make.height.equalTo(38)
        }

        let bodyView = UITextView()
        bodyView.attributedText = makeAgreementText()
        bodyView.backgroundColor = .clear
        bodyView.isEditable = false
        bodyView.isSelectable = false
        bodyView.isScrollEnabled = true
        bodyView.showsVerticalScrollIndicator = false
        bodyView.textContainerInset = .zero
        bodyView.textContainer.lineFragmentPadding = 0
        bodyView.accessibilityLabel = "End User License Agreement"
        card.addSubview(bodyView)
        bodyView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(28)
            make.top.equalToSuperview().offset(80)
            make.bottom.equalToSuperview().inset(76)
        }

        addActions(to: card, top: 665)
    }

    private func makeBackgroundView(imageName: String) -> UIImageView {
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }

    private func makeTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(red: 28 / 255, green: 20 / 255, blue: 34 / 255, alpha: 1)
        label.font = KivroTypography.inter(size: 30, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.78
        return label
    }

    private func addActions(to card: UIView, top: CGFloat) {
        let cancelButton = KivroDialogButton(style: .secondary)
        cancelButton.setTitle(KivroStrings.value("common.cancel"), for: .normal)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)

        let confirmButton = KivroDialogButton(style: .primary)
        confirmButton.setTitle(KivroStrings.value(confirmKey), for: .normal)
        confirmButton.accessibilityHint = isDestructive ? "Permanently removes this account" : nil
        confirmButton.addTarget(self, action: #selector(confirm), for: .touchUpInside)

        card.addSubview(cancelButton)
        card.addSubview(confirmButton)
        cancelButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(top)
            make.width.equalTo(Layout.buttonWidth)
            make.height.equalTo(Layout.buttonHeight)
        }
        confirmButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalTo(cancelButton)
            make.width.equalTo(Layout.buttonWidth)
            make.height.equalTo(Layout.buttonHeight)
        }
    }

    private func makeAgreementText() -> NSAttributedString {
        let text = """
        Welcome to Kivro! To create a positive, safe and standardized space for community interactive content and social sharing, the following content is strictly prohibited on the app:

        1. Any content involving child harm, pornography and other materials detrimental to minors' physical and mental health, including but not limited to texts, images, videos or comments that insult, defame or improperly use minors' portraits and information.

        2. False and harmful public information, including false content generated by AI or other means that disrupts public order, especially fake beauty/lifestyle tutorials, misleading content guidance, and false public opinion content.

        3. Violent content, cyber bullying, and any content that promotes pornography, illegal acts or disrupts the network ecological environment. Specifically, it is forbidden to upload pornographic, violent, bloody content, or use sharing, comment and interaction functions to conduct cyber bullying and spread inappropriate information.

        If any of the above violations are detected, your uploaded works, comments and other published content will be deleted, and your account will be restricted or banned. By clicking the confirmation button, you agree to abide by the Terms of Use and Privacy Policy of Kivro.
        """
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = 16.4
        paragraphStyle.maximumLineHeight = 16.4
        return NSAttributedString(
            string: text,
            attributes: [
                .font: KivroTypography.inter(size: 14.5, weight: .regular),
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    @objc private func cancel() {
        dismiss(animated: true, completion: onCancel)
    }

    @objc private func confirm() {
        dismiss(animated: true, completion: onConfirm)
    }
}
