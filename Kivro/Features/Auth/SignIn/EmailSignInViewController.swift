import UIKit
import SnapKit

final class EmailSignInViewController: KivroViewController, UITextFieldDelegate {
    private let emailField = KivroTextField(localizationKey: "auth.email_placeholder")
    private let passwordField = KivroTextField(localizationKey: "auth.password_placeholder", secure: true)
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
        titleLabel.text = "Sign in"
        titleLabel.textColor = .white
        titleLabel.font = KivroTypography.inter(size: 40, weight: .heavy, italic: true)
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.top.equalToSuperview().offset(198)
        }

        configure(field: emailField, top: 302, returnKey: .next)
        emailField.keyboardType = .emailAddress
        configure(field: passwordField, top: 377, returnKey: .done)

        let forgotButton = UIButton(type: .system)
        forgotButton.setTitle("Forgot Password?", for: .normal)
        forgotButton.setTitleColor(.white, for: .normal)
        forgotButton.titleLabel?.font = KivroTypography.inter(size: 11, weight: .regular)
        forgotButton.contentHorizontalAlignment = .left
        forgotButton.addTarget(self, action: #selector(showForgotPassword), for: .touchUpInside)
        view.addSubview(forgotButton)
        forgotButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(34)
            make.top.equalToSuperview().offset(436)
            make.width.equalTo(130)
            make.height.equalTo(40)
        }

        let signInButton = KivroGradientButton()
        signInButton.setTitle("SIGN IN", for: .normal)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        view.addSubview(signInButton)
        signInButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(36)
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
        } else {
            textField.resignFirstResponder()
        }
        return true
    }

    @objc private func showForgotPassword() {
        navigationController?.pushViewController(ForgotPasswordViewController(), animated: true)
    }

    @objc private func signInTapped() {
        view.endEditing(true)
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            KivroToastPresenter.show(message: KivroStrings.value("common.required"), in: view)
            return
        }
        guard let user = KivroSeedDatabase.shared.authenticate(email: email, password: password) else {
            KivroToastPresenter.show(message: "Invalid email or password.", in: view)
            return
        }
        loadingOverlay.show(in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            KivroSessionState.shared.signIn(
                email: user.email,
                displayName: user.username,
                identifier: user.identifier
            )
            self?.loadingOverlay.hide()
            self?.view.window?.rootViewController = KivroTabBarController()
        }
    }
}
