import UIKit
import SnapKit

enum KivroEULAConsent {
    private static let versionKey = KivroConstantMask.join("kivro.eula.", "accepted.", "version")
    private static let currentVersion = 1

    static var isAccepted: Bool {
        UserDefaults.standard.integer(forKey: versionKey) >= currentVersion
    }

    static func accept() {
        UserDefaults.standard.set(currentVersion, forKey: versionKey)
    }

    static func revoke() {
        UserDefaults.standard.removeObject(forKey: versionKey)
    }
}

final class WelcomeViewController: KivroViewController, UITextViewDelegate {
    private let loadingOverlay = KivroLoadingOverlay()
    private let agreementButton = UIButton(type: .custom)
    private var didPresentInitialEULA = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentInitialEULAIfNeeded()
    }

    private func configureLayout() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        let backdrop = UIImageView(image: UIImage(named: "kivro_welcome_background"))
        backdrop.contentMode = .scaleToFill
        backdrop.clipsToBounds = true
        view.addSubview(backdrop)
        backdrop.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(562)
        }

        let lowerPanel = UIView()
        lowerPanel.backgroundColor = UIColor(red: 20 / 255, green: 15 / 255, blue: 28 / 255, alpha: 1)
        view.addSubview(lowerPanel)
        lowerPanel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(554)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let wordmark = UIImageView(image: UIImage(named: "kivro_wordmark"))
        wordmark.contentMode = .scaleAspectFit
        view.addSubview(wordmark)
        wordmark.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(313)
            make.centerX.equalToSuperview()
            make.width.equalTo(244)
            make.height.equalTo(82)
        }

        let tagline = UILabel()
        tagline.text = KivroStrings.value("brand.tagline")
        tagline.textColor = UIColor(red: 178 / 255, green: 165 / 255, blue: 205 / 255, alpha: 1)
        tagline.font = KivroTypography.inter(size: 10, weight: .regular)
        tagline.textAlignment = .center
        tagline.adjustsFontSizeToFitWidth = true
        view.addSubview(tagline)
        tagline.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(419)
            make.centerX.equalToSuperview()
            make.width.equalTo(271)
            make.height.equalTo(15)
        }

        let newButton = makeButton(key: "auth.new", action: #selector(continueAsGuest(_:)))
        let emailButton = makeButton(key: "auth.email", action: #selector(showEmailSignIn))
        view.addSubview(newButton)
        view.addSubview(emailButton)
        newButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(466)
            make.leading.trailing.equalToSuperview().inset(33)
            make.height.equalTo(60)
        }
        emailButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(540)
            make.leading.trailing.equalToSuperview().inset(33)
            make.height.equalTo(60)
        }

        let signUpButton = UIButton(type: .custom)
        signUpButton.accessibilityLabel = KivroStrings.value("auth.sign_up_link")
        signUpButton.addTarget(self, action: #selector(showSignUp), for: .touchUpInside)
        let prompt = KivroStrings.value("auth.no_account_prompt")
        let signUp = KivroStrings.value("auth.sign_up_link")
        let accountTitle = NSMutableAttributedString(
            string: "\(prompt) \(signUp)",
            attributes: [
                .foregroundColor: UIColor.white,
                .font: KivroTypography.inter(size: 10, weight: .regular)
            ]
        )
        accountTitle.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: (prompt as NSString).length + 1, length: (signUp as NSString).length)
        )
        signUpButton.setAttributedTitle(accountTitle, for: .normal)
        view.addSubview(signUpButton)
        signUpButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(614)
            make.centerX.equalToSuperview()
            make.height.equalTo(30)
        }

        let agreement = UITextView()
        agreement.attributedText = makeAgreementText()
        agreement.backgroundColor = .clear
        agreement.delegate = self
        agreement.isEditable = false
        agreement.isScrollEnabled = false
        agreement.isSelectable = true
        agreement.textContainerInset = .zero
        agreement.textContainer.lineFragmentPadding = 0
        agreement.linkTextAttributes = [
            .foregroundColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        view.addSubview(agreement)
        agreement.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(757)
            make.leading.equalToSuperview().offset(62)
            make.trailing.equalToSuperview().inset(40)
            make.height.equalTo(24)
        }

        agreementButton.isSelected = KivroEULAConsent.isAccepted
        agreementButton.accessibilityLabel = KivroStrings.value("auth.terms_toggle")
        agreementButton.contentHorizontalAlignment = .center
        agreementButton.contentVerticalAlignment = .top
        agreementButton.addTarget(self, action: #selector(toggleAgreement), for: .touchUpInside)
        view.addSubview(agreementButton)
        agreementButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.top.equalTo(agreement)
            make.size.equalTo(20)
        }
        updateAgreementAppearance()

        let homeIndicator = UIView()
        homeIndicator.backgroundColor = .white
        homeIndicator.layer.cornerRadius = 2.5
        view.addSubview(homeIndicator)
        homeIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    private func makeButton(key: String, action: Selector) -> KivroGradientButton {
        let button = KivroGradientButton()
        button.setTitle(KivroStrings.value(key), for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeAgreementText() -> NSAttributedString {
        let text = KivroStrings.value("auth.terms")
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .foregroundColor: UIColor(red: 171 / 255, green: 159 / 255, blue: 191 / 255, alpha: 1),
                .font: KivroTypography.inter(size: 9, weight: .regular)
            ]
        )
        let terms = KivroStrings.value("auth.terms_of_service")
        let privacy = KivroStrings.value("auth.privacy_policy")
        let source = text as NSString
        let termsRange = source.range(of: terms)
        let privacyRange = source.range(of: privacy)
        if termsRange.location != NSNotFound {
            attributedText.addAttribute(.link, value: "kivro-legal://terms", range: termsRange)
        }
        if privacyRange.location != NSNotFound {
            attributedText.addAttribute(.link, value: "kivro-legal://privacy", range: privacyRange)
        }
        return attributedText
    }

    func textView(
        _ textView: UITextView,
        shouldInteractWith URL: URL,
        in characterRange: NSRange,
        interaction: UITextItemInteraction
    ) -> Bool {
        guard URL.scheme == "kivro-legal" else { return true }
        let document: KivroLegalDocument = URL.host == "privacy" ? .privacy : .terms
        navigationController?.pushViewController(
            LegalDocumentsViewController(initialDocument: document),
            animated: true
        )
        return false
    }

    @objc private func showSignUp() {
        guard ensureEULAAccepted() else { return }
        navigationController?.pushViewController(SignUpViewController(), animated: true)
    }

    @objc private func toggleAgreement() {
        agreementButton.isSelected.toggle()
        if agreementButton.isSelected {
            KivroEULAConsent.accept()
        } else {
            KivroEULAConsent.revoke()
        }
        updateAgreementAppearance()
    }

    private func updateAgreementAppearance() {
        agreementButton.setImage(
            UIImage(named: agreementButton.isSelected ? "kivro_terms_selected" : "kivro_terms_unselected"),
            for: .normal
        )
        agreementButton.accessibilityValue = agreementButton.isSelected
            ? KivroStrings.value("common.selected")
            : KivroStrings.value("common.not_selected")
    }

    @objc private func continueAsGuest(_ sender: UIButton) {
        guard ensureEULAAccepted() else { return }
        sender.isEnabled = false
        loadingOverlay.show(in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self, weak sender] in
            KivroSessionState.shared.continueAsGuest()
            self?.loadingOverlay.hide()
            sender?.isEnabled = true
            self?.view.window?.rootViewController = KivroTabBarController()
        }
    }

    @objc private func showEmailSignIn() {
        guard ensureEULAAccepted() else { return }
        navigationController?.pushViewController(EmailSignInViewController(), animated: true)
    }

    private func ensureEULAAccepted() -> Bool {
        guard KivroEULAConsent.isAccepted else {
            KivroToastPresenter.show(
                message: KivroStrings.value("auth.terms_required"),
                in: view
            )
            return false
        }
        return true
    }

    private func presentInitialEULAIfNeeded() {
        guard !didPresentInitialEULA,
              !KivroEULAConsent.isAccepted,
              presentedViewController == nil else { return }
        didPresentInitialEULA = true
        let controller = KivroConfirmationViewController(
            titleKey: "prompt.agreement.title",
            messageKey: "prompt.agreement.message",
            confirmKey: "common.agree"
        ) { [weak self] in
            KivroEULAConsent.accept()
            self?.agreementButton.isSelected = true
            self?.updateAgreementAppearance()
        }
        controller.onCancel = {
            Darwin.exit(EXIT_SUCCESS)
        }
        present(controller, animated: true)
    }
}
