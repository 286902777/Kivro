import UIKit
import SnapKit

final class ForgotPasswordViewController: KivroViewController, UITextFieldDelegate {
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
        titleLabel.text = "Forgot\nPassword"
        titleLabel.numberOfLines = 2
        titleLabel.textColor = .white
        titleLabel.font = KivroTypography.inter(size: 40, weight: .heavy, italic: true)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.top.equalToSuperview().offset(148)
        }

        configure(field: emailField, top: 302, returnKey: .next)
        emailField.keyboardType = .emailAddress
        configure(field: passwordField, top: 377, returnKey: .next)
        configure(field: confirmField, top: 452, returnKey: .done)

        let button = KivroGradientButton()
        button.setTitle("SIGN IN", for: .normal)
        button.addTarget(self, action: #selector(savePassword), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(36)
            make.height.equalTo(60)
        }

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

    @objc private func savePassword() {
        view.endEditing(true)
        guard loadingOverlay.superview == nil else { return }
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
        loadingOverlay.show(in: view)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                try KivroSeedDatabase.shared.updatePassword(email: email, newPassword: password)
                loadingOverlay.hide()
                guard let navigationController else { return }
                navigationController.popViewController(animated: true)
                KivroToastPresenter.show(
                    message: KivroStrings.value("auth.password_updated"),
                    in: navigationController.view
                )
            } catch KivroPasswordResetError.accountNotFound {
                loadingOverlay.hide()
                KivroToastPresenter.show(
                    message: KivroStrings.value("auth.account_not_found"),
                    in: view
                )
            } catch {
                loadingOverlay.hide()
                KivroToastPresenter.show(
                    message: KivroStrings.value("auth.password_update_failed"),
                    in: view
                )
            }
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
