import UIKit
import SnapKit

final class KivroTabBarController: UITabBarController, UITabBarControllerDelegate {
    private var kivroTabBar: KivroTabBar? {
        tabBar as? KivroTabBar
    }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setValue(KivroTabBar(), forKey: "tabBar")
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setValue(KivroTabBar(), forKey: "tabBar")
    }

    override var selectedIndex: Int {
        didSet {
            kivroTabBar?.setSelectedIndex(selectedIndex)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureTabs()
        selectedIndex = KivroTabItem.home.rawValue
        kivroTabBar?.setSelectedIndex(KivroTabItem.home.rawValue)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        kivroTabBar?.setSelectedIndex(selectedIndex)
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        kivroTabBar?.setSelectedIndex(tabBarController.selectedIndex)
    }

    func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        guard let index = viewControllers?.firstIndex(of: viewController) else { return false }
        return canSelectTab(at: index)
    }

    private func canSelectTab(at index: Int) -> Bool {
        guard let item = KivroTabItem(rawValue: index) else { return false }
        switch item {
        case .messages, .profile:
            let presenter = (selectedViewController as? UINavigationController)?.topViewController ?? self
            return KivroAccountAccess.requireAccount(from: presenter)
        case .home, .persona:
            return true
        }
    }

    private func configureTabs() {
        viewControllers = KivroTabItem.allCases.map { item in
            let rootController: UIViewController
            switch item {
            case .home:
                rootController = HomeViewController()
            case .persona:
                rootController = FeedViewController()
            case .messages:
                rootController = MessagesViewController()
            case .profile:
                rootController = ProfileViewController()
            }

            let navigationController = KivroNavigationController(rootViewController: rootController)
            let defaultImage = (
                UIImage(named: item.imageName)
                    ?? UIImage(systemName: item.fallbackSymbolName)
            )?.withRenderingMode(.alwaysOriginal)
            let selectedImage = (
                UIImage(named: item.selectedImageName)
                    ?? UIImage(systemName: item.fallbackSymbolName)
            )?.withRenderingMode(.alwaysOriginal)
            navigationController.tabBarItem = UITabBarItem(
                title: nil,
                image: defaultImage,
                selectedImage: selectedImage
            )
            navigationController.tabBarItem.tag = item.rawValue
            navigationController.tabBarItem.accessibilityLabel = item.accessibilityTitle
            return navigationController
        }
    }
}
