import UIKit

enum KivroAccountAccess {
    @discardableResult
    static func requireAccount(from controller: UIViewController) -> Bool {
        if let user = KivroSessionState.shared.currentUser, !user.isGuest {
            return true
        }
        guard controller.presentedViewController == nil else { return false }
        controller.view.endEditing(true)
        let dialog = KivroConfirmationViewController(
            titleKey: "prompt.login.title",
            messageKey: "prompt.login.message",
            confirmKey: "prompt.login.confirm"
        ) { [weak controller] in
            guard let controller else { return }
            KivroSessionState.shared.relinquishSession()
            let window = controller.viewIfLoaded?.window
                ?? controller.presentingViewController?.viewIfLoaded?.window
            let welcomeController = WelcomeViewController()
            let authorizationNavigationController = KivroNavigationController(
                rootViewController: welcomeController
            )
            authorizationNavigationController.setNavigationBarHidden(true, animated: false)
            let signInController = EmailSignInViewController()
            signInController.hidesBottomBarWhenPushed = true
            authorizationNavigationController.pushViewController(signInController, animated: false)
            window?.rootViewController = authorizationNavigationController
        }
        controller.present(dialog, animated: true)
        return false
    }
}
