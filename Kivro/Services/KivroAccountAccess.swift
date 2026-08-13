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
            let navigationController = (controller as? UINavigationController)
                ?? controller.navigationController
                ?? ((controller as? UITabBarController)?.selectedViewController as? UINavigationController)
                ?? (controller.tabBarController?.selectedViewController as? UINavigationController)
            let signInController = EmailSignInViewController()
            signInController.hidesBottomBarWhenPushed = true
            navigationController?.pushViewController(signInController, animated: true)
        }
        controller.present(dialog, animated: true)
        return false
    }
}
