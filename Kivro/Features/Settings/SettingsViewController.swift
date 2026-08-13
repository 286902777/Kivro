import UIKit
import SnapKit

final class SettingsViewController: KivroViewController {
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

        let header = KivroPageHeaderView(title: "Settings")
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        addRow(title: KivroStrings.value("settings.privacy"), top: 118, action: #selector(showPrivacy))
        addRow(title: KivroStrings.value("settings.user_agreement"), top: 179, action: #selector(showUserAgreement))
        addRow(title: KivroStrings.value("settings.blacklist"), top: 240, action: #selector(showBlacklist))
        addRow(title: KivroStrings.value("settings.logout"), top: 301, action: #selector(confirmSignOut))
        addRow(title: KivroStrings.value("settings.delete"), top: 362, action: #selector(confirmDeleteAccount))

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

    private func addRow(title: String, top: CGFloat, action: Selector) {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = KivroTypography.inter(size: 18, weight: .bold)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(26)
            make.top.equalToSuperview().offset(top)
            make.height.equalTo(54)
        }

        let chevron = UIImageView(image: UIImage(named: "kivro_chevron_right"))
        chevron.contentMode = .scaleAspectFit
        button.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
    }

    @objc private func showPrivacy() {
        navigationController?.pushViewController(
            LegalDocumentsViewController(initialDocument: .privacy),
            animated: true
        )
    }

    @objc private func showUserAgreement() {
        navigationController?.pushViewController(
            LegalDocumentsViewController(initialDocument: .terms),
            animated: true
        )
    }

    @objc private func showBlacklist() {
        navigationController?.pushViewController(UserListViewController(mode: .blacklist), animated: true)
    }

    @objc private func confirmSignOut() {
        let controller = KivroConfirmationViewController(
            titleKey: "prompt.sign_out.title",
            messageKey: "prompt.sign_out.message",
            confirmKey: "common.sign_out"
        ) { [weak self] in self?.performSignOut() }
        present(controller, animated: true)
    }

    @objc private func confirmDeleteAccount() {
        let controller = KivroConfirmationViewController(
            titleKey: "prompt.delete.title",
            messageKey: "prompt.delete.message",
            confirmKey: "common.delete",
            isDestructive: true
        ) { [weak self] in self?.performDeleteAccount() }
        present(controller, animated: true)
    }

    private func performDeleteAccount() {
        guard loadingOverlay.superview == nil else { return }
        guard let user = KivroSessionState.shared.currentUser, !user.isGuest else {
            KivroToastPresenter.show(message: KivroStrings.value("auth.sign_in_required"), in: view)
            return
        }
        loadingOverlay.show(in: view)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                let artifacts = try KivroSeedDatabase.shared.deleteAccount(
                    userIdentifier: user.identifier
                )
                _ = KivroCoinWallet.shared.deleteWallet(for: user.identifier)
                KivroProfileState.shared.clear(for: user.identifier)
                KivroProductState.shared.clear(for: user.identifier)
                KivroPostStore.shared.removePosts(authorIdentifier: user.identifier)
                KivroVideoMedia.shared.deletePersistedMedia(paths: artifacts.mediaPaths)
                KivroSessionState.shared.relinquishSession()
                loadingOverlay.hide()

                let authorizationController = KivroNavigationController(
                    rootViewController: WelcomeViewController()
                )
                view.window?.rootViewController = authorizationController
                KivroToastPresenter.show(
                    message: KivroStrings.value("settings.account_deleted"),
                    in: authorizationController.view
                )
            } catch {
                loadingOverlay.hide()
                KivroToastPresenter.show(
                    message: KivroStrings.value("settings.delete_failed"),
                    in: view
                )
            }
        }
    }

    private func performSignOut() {
        guard loadingOverlay.superview == nil else { return }
        loadingOverlay.show(in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let self else { return }
            KivroSessionState.shared.relinquishSession()
            loadingOverlay.hide()
            let welcomeController = KivroNavigationController(rootViewController: WelcomeViewController())
            view.window?.rootViewController = welcomeController
            guard let targetView = welcomeController.view else { return }
            KivroToastPresenter.show(message: KivroStrings.value("common.signed_out"), in: targetView)
        }
    }
}
