import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    private func makeRootViewController() -> UIViewController {
#if DEBUG
        switch ProcessInfo.processInfo.environment["KIVRO_QA_SCREEN"] {
        case "tabs":
            return KivroTabBarController()
        case "dialog_eula", "dialog_coins", "dialog_login", "dialog_chat", "dialog_launch", "dialog_persona", "dialog_signout", "dialog_delete":
            return makeTabController(selectedIndex: KivroTabItem.home.rawValue)
        case "feed_tab":
            return makeTabController(selectedIndex: KivroTabItem.persona.rawValue)
        case "messages_tab":
            return makeTabController(selectedIndex: KivroTabItem.messages.rawValue)
        case "profile_tab":
            return makeTabController(selectedIndex: KivroTabItem.profile.rawValue)
        case "welcome":
            return KivroNavigationController(rootViewController: WelcomeViewController())
        case "sign_in":
            return KivroNavigationController(rootViewController: EmailSignInViewController())
        case "sign_up":
            return KivroNavigationController(rootViewController: SignUpViewController())
        case "forgot_password":
            return KivroNavigationController(rootViewController: ForgotPasswordViewController())
        case "profile_setup":
            return KivroNavigationController(rootViewController: ProfileSetupViewController())
        case "edit_profile":
            return KivroNavigationController(rootViewController: EditProfileViewController())
        case "settings":
            return KivroNavigationController(rootViewController: SettingsViewController())
        case "following":
            return KivroNavigationController(rootViewController: UserListViewController(mode: .following))
        case "followers":
            return KivroNavigationController(rootViewController: UserListViewController(mode: .followers))
        case "blacklist":
            return KivroNavigationController(rootViewController: UserListViewController(mode: .blacklist))
        case "composer":
            return KivroNavigationController(rootViewController: PostComposerViewController())
        case "report":
            return KivroNavigationController(rootViewController: ReportViewController())
        case "persona_fit":
            return KivroNavigationController(rootViewController: PersonaFitViewController())
        case "persona_analyzed":
            return KivroNavigationController(rootViewController: PersonaFitViewController(isAnalyzed: true))
        case "persona_card":
            return KivroNavigationController(rootViewController: PersonaCardViewController())
        case "creator":
            signInAsQAUser(identifier: "soren")
            try? KivroSeedDatabase.shared.setFollowing(
                false,
                sourceIdentifier: "soren",
                targetIdentifier: "freja"
            )
            return KivroNavigationController(
                rootViewController: CreatorProfileViewController(
                    creatorIdentifier: "freja",
                    currentUserIdentifier: KivroSessionState.shared.currentUserIdentifier
                )
            )
        case "creator_followed":
            signInAsQAUser(identifier: "soren")
            try? KivroSeedDatabase.shared.setFollowing(
                true,
                sourceIdentifier: "soren",
                targetIdentifier: "freja"
            )
            return KivroNavigationController(
                rootViewController: CreatorProfileViewController(
                    creatorIdentifier: "freja",
                    currentUserIdentifier: KivroSessionState.shared.currentUserIdentifier
                )
            )
        case "creator_chat_locked":
            signInAsQAUser(identifier: "soren")
            try? KivroSeedDatabase.shared.setFollowing(
                true,
                sourceIdentifier: "soren",
                targetIdentifier: "freja"
            )
            try? KivroSeedDatabase.shared.setFollowing(
                false,
                sourceIdentifier: "freja",
                targetIdentifier: "soren"
            )
            return KivroNavigationController(
                rootViewController: CreatorProfileViewController(
                    creatorIdentifier: "freja",
                    currentUserIdentifier: "soren"
                )
            )
        case "feed_blocked":
            signInAsQAUser(identifier: "soren")
            try? KivroSeedDatabase.shared.setBlocked(
                true,
                sourceIdentifier: "soren",
                targetIdentifier: "freja"
            )
            return KivroNavigationController(rootViewController: FeedViewController())
        case "chat":
            signInAsQAUser(identifier: "soren")
            return KivroNavigationController(rootViewController: ChatViewController())
        case "chat_voice":
            signInAsQAUser(identifier: "soren")
            return KivroNavigationController(rootViewController: ChatViewController())
        case "more":
            return KivroNavigationController(rootViewController: ChatViewController())
        case "feed":
            return KivroNavigationController(rootViewController: FeedViewController())
        case "feed_video":
            return KivroNavigationController(rootViewController: FeedViewController(showsVideo: true))
        case "comments":
            return KivroNavigationController(rootViewController: FeedViewController())
        case "recharge":
            return KivroNavigationController(rootViewController: RechargeViewController())
        case "messages":
            return KivroNavigationController(rootViewController: MessagesViewController())
        case "profile":
            return KivroNavigationController(rootViewController: ProfileViewController())
        case "profile_multi":
            signInAsQAUser(identifier: "soren")
            KivroPostStore.shared.prepend(
                PostPreview(
                    authorIdentifier: "soren",
                    authorName: "Soren",
                    avatarAssetName: "m1",
                    bodyText: "Second work item for profile list verification.",
                    mediaAssetNames: ["aa6f52fad4fa275dfec71a5f95572c1e"],
                    category: "Mecha"
                )
            )
            return KivroNavigationController(rootViewController: ProfileViewController())
        case "registration_database":
            let email = KivroConstantMask.join("qa.registration", "@kivro.", "app")
            let password = KivroConstantMask.join("12", "34", "56")
            let database = KivroSeedDatabase.shared
            let user = database.authenticate(email: email, password: password)
                ?? (try? database.registerUser(
                    identifier: "qa_registration_user",
                    username: "QA Member",
                    gender: "female",
                    birthday: Date(timeIntervalSince1970: 946_684_800),
                    countryCode: "US",
                    avatarAssetName: "kivro_default_profile_avatar",
                    email: email,
                    password: password
                ))
            if let user {
                KivroSessionState.shared.signIn(
                    email: user.email,
                    displayName: user.username,
                    identifier: user.identifier
                )
            }
            return KivroNavigationController(rootViewController: ProfileViewController())
        default:
            return SplashViewController()
        }
#else
        return SplashViewController()
#endif
    }

#if DEBUG
    private func signInAsQAUser(identifier: String) {
        guard let user = KivroSeedDatabase.shared.user(identifier: identifier) else { return }
        KivroSessionState.shared.signIn(
            email: user.email,
            displayName: user.username,
            identifier: user.identifier
        )
    }

    private func makeTabController(selectedIndex: Int) -> UIViewController {
        let controller = KivroTabBarController()
        controller.loadViewIfNeeded()
        controller.selectedIndex = selectedIndex
        return controller
    }
#endif
}
