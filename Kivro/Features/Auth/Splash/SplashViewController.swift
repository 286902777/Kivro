import UIKit
import SnapKit

final class SplashViewController: KivroViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
#if DEBUG
        if ProcessInfo.processInfo.environment["KIVRO_QA_SCREEN"] == "splash" { return }
#endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { [weak self] in
            self?.showNextScreen()
        }
    }

    private func configureLayout() {
        let backdrop = UIImageView(image: UIImage(named: "kivro_launch_cosplay_background"))
        backdrop.contentMode = .scaleAspectFill
        backdrop.clipsToBounds = true
        view.addSubview(backdrop)
        backdrop.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func showNextScreen() {
        guard let window = view.window else { return }
        let controller: UIViewController
        if KivroSessionState.shared.isAuthenticated {
            controller = KivroTabBarController()
        } else {
            let navigationController = KivroNavigationController(rootViewController: WelcomeViewController())
            navigationController.setNavigationBarHidden(true, animated: false)
            controller = navigationController
        }
        UIView.transition(with: window, duration: 0.28, options: .transitionCrossDissolve) {
            window.rootViewController = controller
        }
    }
}
