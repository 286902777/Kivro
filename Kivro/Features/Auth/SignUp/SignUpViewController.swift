import UIKit
import SnapKit

final class SignUpViewController: KivroViewController, UITextFieldDelegate {
    private let emailField = KivroTextField(localizationKey: "auth.email_placeholder")
    private let passwordField = KivroTextField(localizationKey: "auth.password_placeholder", secure: true)
    private let confirmField = KivroTextField(localizationKey: "auth.confirm_password_placeholder", secure: true)
    private let loadingOverlay = KivroLoadingOverlay()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = KivroPageHeaderView(title: "")
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        let titleLabel = UILabel()
        titleLabel.text = "Sign up"
        titleLabel.textColor = .white
        titleLabel.font = KivroTypography.inter(size: 40, weight: .heavy, italic: true)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.top.equalToSuperview().offset(198)
        }

        configure(field: emailField, top: 302, returnKey: .next)
        emailField.keyboardType = .emailAddress
        configure(field: passwordField, top: 377, returnKey: .next)
        configure(field: confirmField, top: 452, returnKey: .done)

        let button = KivroGradientButton()
        button.setTitle("SIGN UP", for: .normal)
        button.addTarget(self, action: #selector(continueProfile), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            make.top.equalToSuperview().offset(703)
            make.height.equalTo(60)
        }

        addHomeIndicator()
    }

    private func configure(field: KivroTextField, top: CGFloat, returnKey: UIReturnKeyType) {
        field.delegate = self
        field.returnKeyType = returnKey
        view.addSubview(field)
        field.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.top.equalToSuperview().offset(top)
            make.height.equalTo(48)
        }
    }

    private func addHomeIndicator() {
        let indicator = UIView()
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = 2.5
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === emailField {
            passwordField.becomeFirstResponder()
        } else if textField === passwordField {
            confirmField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @objc private func continueProfile() {
        view.endEditing(true)
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordField.text,
              !password.isEmpty,
              let confirmation = confirmField.text,
              !confirmation.isEmpty else {
            KivroToastPresenter.show(message: KivroStrings.value("common.required"), in: view)
            return
        }
        guard Self.isValidEmail(email) else {
            KivroToastPresenter.show(message: KivroStrings.value("auth.invalid_email"), in: view)
            return
        }
        guard password.count >= 6 else {
            KivroToastPresenter.show(
                message: KivroStrings.value("auth.password_min_length"),
                in: view
            )
            return
        }
        guard password == confirmation else {
            KivroToastPresenter.show(
                message: KivroStrings.value("auth.password_mismatch"),
                in: view
            )
            return
        }
        guard !KivroSeedDatabase.shared.hasUser(email: email) else {
            KivroToastPresenter.show(message: KivroStrings.value("auth.email_exists"), in: view)
            return
        }
        loadingOverlay.show(in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            KivroSessionState.shared.beginRegistration(email: email, password: password)
            self?.loadingOverlay.hide()
            self?.navigationController?.pushViewController(ProfileSetupViewController(), animated: true)
        }
    }

    private static func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return value.range(
            of: pattern,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}
