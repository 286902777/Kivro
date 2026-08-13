import UIKit
import SnapKit

final class MoreActionsViewController: UIViewController {
    var onBlocked: (() -> Void)?

    private let targetUserIdentifier: String
    private let currentUserIdentifier: String

    init(targetUserIdentifier: String, currentUserIdentifier: String) {
        self.targetUserIdentifier = targetUserIdentifier
        self.currentUserIdentifier = currentUserIdentifier
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard targetUserIdentifier != currentUserIdentifier else {
            dismiss(animated: false)
            return
        }
        configureLayout()
    }

    private func configureLayout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.58)

        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 20
        sheet.clipsToBounds = true
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(13)
            make.top.equalToSuperview().offset(541)
            make.height.equalTo(238)
        }

        let reportButton = makeButton(title: "Report", selector: #selector(report))
        let blockButton = makeButton(title: "Block", selector: #selector(block))
        let cancelButton = makeButton(title: "Cancel", selector: #selector(cancel))
        sheet.addSubview(reportButton)
        sheet.addSubview(blockButton)
        sheet.addSubview(cancelButton)
        reportButton.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(81)
        }
        blockButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(81)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(82)
        }
        cancelButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(165)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let divider = UIView()
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        sheet.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(163)
            make.height.equalTo(2)
        }

        let indicator = UIView()
        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 2.5
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    private func makeButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = KivroTypography.inter(size: 20, weight: .medium)
        button.addTarget(self, action: selector, for: .touchUpInside)
        return button
    }

    @objc private func report() {
        guard targetUserIdentifier != currentUserIdentifier else { return }
        let navigationController = reportNavigationController()
        dismiss(animated: true) {
            navigationController?.pushViewController(ReportViewController(), animated: true)
        }
    }

    private func reportNavigationController() -> UINavigationController? {
        if let navigationController = presentingViewController as? UINavigationController {
            return navigationController
        }
        if let tabBarController = presentingViewController as? UITabBarController {
            return tabBarController.selectedViewController as? UINavigationController
        }
        return presentingViewController?.navigationController
    }

    @objc private func block() {
        guard targetUserIdentifier != currentUserIdentifier else { return }
        do {
            try KivroSeedDatabase.shared.setBlocked(
                true,
                sourceIdentifier: currentUserIdentifier,
                targetIdentifier: targetUserIdentifier
            )
            let presenterView = presentingViewController?.navigationController?.view
                ?? presentingViewController?.view
            dismiss(animated: true) {
                guard let presenterView else { return }
                KivroToastPresenter.show(
                    message: KivroStrings.value("social.blocked"),
                    in: presenterView
                )
                self.onBlocked?()
            }
        } catch {
            KivroToastPresenter.show(message: KivroStrings.value("social.update_failed"), in: view)
        }
    }
    @objc private func cancel() { dismiss(animated: true) }
}
