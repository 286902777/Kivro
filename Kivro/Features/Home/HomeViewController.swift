import UIKit
import SnapKit

final class HomeViewController: KivroViewController {
    private let contentScrollView = UIScrollView()
    private let contentView = UIView()
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let radarPrice = 300
    private let loadingOverlay = KivroLoadingOverlay()
    private let balanceLabel = UILabel()
    private let costLabel = UILabel()
    private let costCoinImage = UIImageView(image: UIImage(named: "kivro_coin_badge"))
    private let filterTitles = ["All", "Anime", "Cyber", "Fantasy", "Gothic", "Mecha", "Period"]
    private var filterButtons: [UIButton] = []
    private var radarButtons: [UIButton] = []
    private var displayedProfiles: [KivroRadarProfile] = []
    private var selectedArchetype = "All"
    private var didPresentQADialog = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(walletDidChange),
            name: .kivroCoinBalanceDidChange,
            object: nil
        )
        refreshProductState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshProductState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if DEBUG
        if presentQADialogIfNeeded() { return }
#endif
        guard KivroFirstHomeLoadingState.consume() else { return }
        loadingOverlay.show(in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.loadingOverlay.hide()
        }
    }

#if DEBUG
    private func presentQADialogIfNeeded() -> Bool {
        guard !didPresentQADialog,
              let route = ProcessInfo.processInfo.environment["KIVRO_QA_SCREEN"] else { return false }
        let specification: (String, String, String, Bool)?
        switch route {
        case "dialog_eula": specification = ("prompt.agreement.title", "prompt.agreement.message", "common.agree", false)
        case "dialog_coins": specification = ("prompt.coins.title", "prompt.coins.message", "common.confirm", false)
        case "dialog_login": specification = ("prompt.login.title", "prompt.login.message", "prompt.login.confirm", false)
        case "dialog_chat": specification = ("prompt.chat.title", "prompt.chat.message", "common.done", false)
        case "dialog_launch": specification = ("prompt.launch.title", "prompt.launch.message", "common.confirm", false)
        case "dialog_persona": specification = ("prompt.persona.title", "prompt.persona.message", "common.confirm", false)
        case "dialog_signout": specification = ("prompt.sign_out.title", "prompt.sign_out.message", "common.confirm", false)
        case "dialog_delete": specification = ("prompt.delete.title", "prompt.delete.message", "common.delete", true)
        default: specification = nil
        }
        guard let specification else { return false }
        didPresentQADialog = true
        present(
            KivroConfirmationViewController(
                titleKey: specification.0,
                messageKey: specification.1,
                confirmKey: specification.2,
                isDestructive: specification.3
            ) {},
            animated: false
        )
        return true
    }
#endif

    private func configureLayout() {
        let backgroundView = KivroHomeBackgroundView()
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.alwaysBounceVertical = false
        contentScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentScrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalTo(contentScrollView.contentLayoutGuide)
            make.centerX.equalTo(contentScrollView.frameLayoutGuide)
            make.width.equalTo(contentScrollView.frameLayoutGuide).priority(.high)
            make.width.lessThanOrEqualTo(430)
            make.height.equalTo(760)
        }

        configurePersonaFitEntry()
        configureFilters()
        configureRadarDots()
        configureRadarProfiles()
        configureLaunchButton()
    }

    private func configurePersonaFitEntry() {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.accessibilityLabel = "Open AI Persona Fit"
        button.addTarget(self, action: #selector(showPersonaFit), for: .touchUpInside)
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(46)
            make.top.equalToSuperview().offset(196)
            make.height.equalTo(62)
        }
    }

    private func configureFilters() {
        let balanceButton = UIButton(type: .custom)
        balanceButton.backgroundColor = UIColor(red: 128 / 255, green: 34 / 255, blue: 203 / 255, alpha: 1)
        balanceButton.layer.cornerRadius = 15
        balanceButton.addTarget(self, action: #selector(showRecharge), for: .touchUpInside)
        contentView.addSubview(balanceButton)
        balanceButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(10)
            make.top.equalToSuperview().offset(273)
            make.width.equalTo(86)
            make.height.equalTo(30)
        }

        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.isDirectionalLockEnabled = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 11, bottom: 0, right: 0)
        contentView.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.equalTo(balanceButton.snp.leading).offset(-16)
            make.top.equalToSuperview().offset(273)
            make.height.equalTo(30)
        }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide)
            make.top.bottom.equalTo(scrollView.frameLayoutGuide)
            make.height.equalTo(scrollView.frameLayoutGuide)
            make.width.greaterThanOrEqualTo(scrollView.frameLayoutGuide)
        }

        filterButtons = filterTitles.enumerated().map { index, title in
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = KivroTypography.inter(size: 15, weight: .bold)
            button.layer.cornerRadius = 15
            button.addTarget(self, action: #selector(selectFilter(_:)), for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.width.equalTo(max(58, title.count * 10 + 28))
                make.height.equalTo(30)
            }
            stack.addArrangedSubview(button)
            return button
        }
        updateFilterAppearance()

        let coinImage = UIImageView(image: UIImage(named: "kivro_coin_badge"))
        coinImage.contentMode = .scaleAspectFit
        balanceButton.addSubview(coinImage)
        coinImage.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(7)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        balanceLabel.textColor = .white
        balanceLabel.font = KivroTypography.inter(size: 14, weight: .bold)
        balanceLabel.adjustsFontSizeToFitWidth = true
        balanceButton.addSubview(balanceLabel)
        balanceLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinImage.snp.trailing).offset(1)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
        }
    }

    private func configureRadarDots() {
        let dots: [(CGFloat, CGFloat, CGFloat)] = [
            (312, 540, 0.1), (318, 478, 0.2), (272, 470, 0.1), (308, 417, 0.2),
            (252, 365, 0.1), (217, 355, 0.2), (150, 353, 0.1), (86, 390, 0.2),
            (106, 439, 0.1), (140, 516, 0.2), (156, 616, 0.2), (225, 610, 0.1),
            (259, 596, 0.2), (91, 580, 0.2), (88, 553, 0.1), (53, 500, 0.1)
        ]
        dots.forEach { x, y, opacity in
            let dot = UIView()
            dot.backgroundColor = UIColor.white.withAlphaComponent(opacity)
            dot.layer.cornerRadius = 6
            contentView.addSubview(dot)
            dot.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(x)
                make.top.equalToSuperview().offset(y)
                make.size.equalTo(12)
            }
        }
    }

    private func configureRadarProfiles() {
        let positions: [(CGFloat, CGFloat, CGFloat)] = [(111, 401, 54), (210, 466, 58), (139, 548, 52)]
        radarButtons = positions.enumerated().map { index, position in
            let button = UIButton(type: .custom)
            button.tag = index
            button.imageView?.contentMode = .scaleAspectFill
            button.clipsToBounds = true
            button.layer.cornerRadius = position.2 / 2
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.65).cgColor
            button.addTarget(self, action: #selector(openRadarProfile(_:)), for: .touchUpInside)
            contentView.addSubview(button)
            button.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(position.0)
                make.top.equalToSuperview().offset(position.1)
                make.size.equalTo(position.2)
            }
            return button
        }
        randomizeRadarProfiles()
    }

    private func configureLaunchButton() {
        let button = KivroGradientButton()
        button.setTitle("LAUNCH RADAR", for: .normal)
        button.addTarget(self, action: #selector(launchRadar), for: .touchUpInside)
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(36)
            make.top.equalToSuperview().offset(658)
            make.height.equalTo(60)
        }

        let costBadge = UIView()
        costBadge.backgroundColor = UIColor(red: 100 / 255, green: 91 / 255, blue: 1, alpha: 1)
        costBadge.layer.cornerRadius = 12
        contentView.addSubview(costBadge)
        costBadge.snp.makeConstraints { make in
            make.trailing.equalTo(button).inset(1)
            make.top.equalTo(button).offset(-7)
            make.width.equalTo(74)
            make.height.equalTo(24)
        }

        costCoinImage.contentMode = .scaleAspectFit
        costBadge.addSubview(costCoinImage)
        costCoinImage.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(9)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }

        costLabel.textColor = .white
        costLabel.font = KivroTypography.inter(size: 13, weight: .bold)
        costLabel.adjustsFontSizeToFitWidth = true
        costBadge.addSubview(costLabel)
        costLabel.snp.makeConstraints { make in
            make.leading.equalTo(costCoinImage.snp.trailing).offset(2)
            make.trailing.equalToSuperview().inset(7)
            make.centerY.equalToSuperview()
        }
    }

    private func refreshProductState() {
        balanceLabel.text = String(KivroCoinWallet.shared.balance(for: currentUserIdentifier))
        costCoinImage.isHidden = false
        costLabel.snp.remakeConstraints { make in
            make.leading.equalTo(costCoinImage.snp.trailing).offset(2)
            make.trailing.equalToSuperview().inset(7)
            make.centerY.equalToSuperview()
        }
        costLabel.textAlignment = .left
        costLabel.text = String(radarPrice)
    }

    private func randomizeRadarProfiles() {
        let radarProfiles = KivroRadarProfile.all
        let targetCount = selectedArchetype == "All" ? 3 : Int.random(in: 2...3)
        if selectedArchetype == "All" {
            displayedProfiles = Array(radarProfiles.shuffled().prefix(targetCount))
        } else {
            let matching = radarProfiles.filter { $0.archetype == selectedArchetype }.shuffled()
            displayedProfiles = Array(matching.prefix(targetCount))
            let selectedIdentifiers = Set(displayedProfiles.map(\.identifier))
            let fallback = radarProfiles
                .filter { !selectedIdentifiers.contains($0.identifier) }
                .shuffled()
            displayedProfiles.append(contentsOf: fallback.prefix(targetCount - displayedProfiles.count))
        }

        radarButtons.forEach { button in
            button.isHidden = true
            button.setImage(nil, for: .normal)
            button.accessibilityLabel = nil
        }
        zip(radarButtons, displayedProfiles).forEach { button, profile in
            button.isHidden = false
            button.setImage(UIImage(named: profile.avatarAssetName), for: .normal)
            button.accessibilityLabel = "\(profile.name), \(profile.archetype) cosplayer"
        }
    }

    private func updateFilterAppearance() {
        for (index, button) in filterButtons.enumerated() {
            let isSelected = filterTitles[index] == selectedArchetype
            button.backgroundColor = isSelected
                ? UIColor(red: 128 / 255, green: 34 / 255, blue: 203 / 255, alpha: 1)
                : UIColor.white.withAlphaComponent(0.2)
        }
    }

    private func presentInsufficientCoins() {
        present(
            KivroConfirmationViewController(
                titleKey: "prompt.coins.title",
                messageKey: "prompt.coins.message",
                confirmKey: "common.recharge"
            ) { [weak self] in self?.showRecharge() },
            animated: true
        )
    }

    private func completePaidRadarLaunch() {
        loadingOverlay.show(in: view)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let succeeded = KivroCoinWallet.shared.spend(radarPrice, for: currentUserIdentifier)
            loadingOverlay.hide()
            guard succeeded else {
                KivroToastPresenter.show(message: "Unable to launch Radar. Try again.", in: view)
                return
            }
            KivroProductState.shared.grantRadarProfileAccess(for: currentUserIdentifier)
            randomizeRadarProfiles()
            refreshProductState()
        }
    }

    @objc private func launchRadar() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        guard KivroCoinWallet.shared.balance(for: currentUserIdentifier) >= radarPrice else {
            presentInsufficientCoins()
            return
        }
        present(
            KivroConfirmationViewController(
                titleKey: "prompt.launch.title",
                messageKey: "prompt.launch.message",
                confirmKey: "common.confirm"
            ) { [weak self] in self?.completePaidRadarLaunch() },
            animated: true
        )
    }

    @objc private func selectFilter(_ sender: UIButton) {
        selectedArchetype = filterTitles[sender.tag]
        updateFilterAppearance()
        randomizeRadarProfiles()
    }

    @objc private func openRadarProfile(_ sender: UIButton) {
        guard displayedProfiles.indices.contains(sender.tag) else { return }
        guard KivroProductState.shared.consumeRadarProfileAccess(
            for: currentUserIdentifier
        ) else { return }
        let profile = displayedProfiles[sender.tag]
        present(KivroRadarReplyViewController(profile: profile), animated: true)
    }

    @objc private func walletDidChange() {
        refreshProductState()
    }

    @objc private func showPersonaFit() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        navigationController?.pushViewController(PersonaFitViewController(), animated: true)
    }

    @objc private func showRecharge() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        navigationController?.pushViewController(RechargeViewController(), animated: true)
    }
}
