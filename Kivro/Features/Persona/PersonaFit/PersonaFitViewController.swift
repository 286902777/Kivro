import UIKit
import SnapKit
import PhotosUI

final class PersonaFitViewController: KivroViewController, PHPickerViewControllerDelegate {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let personaCardUnlockPrice = 300
    private var isAnalyzed: Bool
    private var analyzedImage: UIImage?
    private var analyzedScores: [Int]
    private let loadingOverlay = KivroLoadingOverlay()
    private let contentScrollView = UIScrollView()
    private let contentView = UIView()
    private weak var personaCardButton: KivroGradientButton?
    private weak var personaCardCostBadge: UIView?
    private weak var lockedResultsMaskContainer: UIView?
    private var lockedResultsBlurAnimator: UIViewPropertyAnimator?

    init(isAnalyzed: Bool = false, analyzedImage: UIImage? = nil) {
        self.isAnalyzed = isAnalyzed
        self.analyzedImage = analyzedImage
        analyzedScores = Self.makeAnalyzedScores()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    private static func makeAnalyzedScores() -> [Int] {
        let cyberScore = Int.random(in: 80...99)
        let otherScores = (0..<5).map { _ in Int.random(in: 10..<cyberScore) }
        return [cyberScore] + otherScores
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshPersonaCardButtonState()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        finalizeLockedResultsBlurAnimator()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(contentScrollView)
        contentScrollView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(105)
            make.leading.trailing.bottom.equalToSuperview()
        }
        contentScrollView.addSubview(contentView)
        contentView.snp.remakeConstraints { make in
            make.top.bottom.equalTo(contentScrollView.contentLayoutGuide)
            make.centerX.equalTo(contentScrollView.frameLayoutGuide)
            make.width.equalTo(contentScrollView.frameLayoutGuide).priority(.high)
            make.width.lessThanOrEqualTo(375)
            make.height.equalTo(707)
        }

        let backButton = KivroBackButton()
        backButton.addTarget(self, action: #selector(closeScreen), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(54)
            make.size.equalTo(40)
        }

        let title = UILabel()
        title.text = "AI Persona Fit"
        title.textColor = .white
        title.font = KivroTypography.inter(size: 30, weight: .bold)
        view.addSubview(title)
        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(77)
            make.top.equalToSuperview().offset(57)
        }

        configureUploadCard()
        configureScoreCard()
    }

    private func configureUploadCard() {
        let card = KivroPersonaUploadCardView()
        card.layer.cornerRadius = 29
        card.clipsToBounds = false
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(19)
            make.top.equalToSuperview().offset(22)
            make.height.equalTo(196)
        }

        let uploadTitle = UILabel()
        uploadTitle.text = isAnalyzed ? "ANALYSIS\nCOMPLETE" : "TAP TO UPLOAD\nPHOTO"
        uploadTitle.textColor = .black
        uploadTitle.font = KivroTypography.inter(size: 24, weight: .heavy)
        uploadTitle.numberOfLines = 2
        card.addSubview(uploadTitle)
        uploadTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(19)
            make.top.equalToSuperview().offset(20)
            make.width.equalTo(200)
        }

        let subtitle = UILabel()
        subtitle.text = "Upload a photo to discover your\nbest-matching cosplay archetype"
        subtitle.textColor = UIColor(red: 143 / 255, green: 133 / 255, blue: 151 / 255, alpha: 1)
        subtitle.font = KivroTypography.inter(size: 13, weight: .regular)
        subtitle.numberOfLines = 2
        card.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(19)
            make.top.equalToSuperview().offset(83)
        }

        let fallbackImage = UIImage(named: isAnalyzed ? "kivro_persona_analysis_portrait" : "kivro_persona_upload_primary")
        let female = UIImageView(image: analyzedImage ?? fallbackImage)
        female.contentMode = .scaleAspectFill
        female.clipsToBounds = true
        female.layer.cornerRadius = 11
        card.addSubview(female)
        female.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(isAnalyzed ? 226 : 210)
            make.top.equalToSuperview().offset(isAnalyzed ? -32 : -20)
            make.width.equalTo(isAnalyzed ? 96 : 78)
            make.height.equalTo(isAnalyzed ? 138 : 111)
        }

        if !isAnalyzed {
            let male = UIImageView(image: UIImage(named: "kivro_persona_upload_secondary"))
            male.contentMode = .scaleAspectFill
            male.clipsToBounds = true
            male.layer.cornerRadius = 11
            male.transform = CGAffineTransform(rotationAngle: 8 * .pi / 180)
            card.addSubview(male)
            male.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(258)
                make.top.equalToSuperview().offset(-11)
                make.width.equalTo(80)
                make.height.equalTo(111)
            }
        }

        let hintButton = UIButton(type: .system)
        hintButton.setTitle(isAnalyzed ? "✓  Persona fit analysis ready" : "⌗  Portrait photos work best", for: .normal)
        hintButton.setTitleColor(UIColor(red: 210 / 255, green: 166 / 255, blue: 1, alpha: 1), for: .normal)
        hintButton.titleLabel?.font = KivroTypography.inter(size: 13, weight: .bold)
        hintButton.backgroundColor = .black
        hintButton.layer.cornerRadius = 25.5
        hintButton.addTarget(self, action: #selector(analyzePhoto), for: .touchUpInside)
        card.addSubview(hintButton)
        hintButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(15)
            make.top.equalToSuperview().offset(131)
            make.height.equalTo(51)
        }

        guard !isAnalyzed else { return }
        let uploadButton = UIButton(type: .custom)
        uploadButton.accessibilityLabel = "Choose a portrait photo"
        uploadButton.addTarget(self, action: #selector(analyzePhoto), for: .touchUpInside)
        card.addSubview(uploadButton)
        uploadButton.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.bottom.equalTo(hintButton.snp.top)
        }
    }

    private func configureScoreCard() {
        let panel = UIView()
        panel.backgroundColor = UIColor(red: 48 / 255, green: 43 / 255, blue: 54 / 255, alpha: 1)
        panel.layer.cornerRadius = 29
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(272)
            make.height.equalTo(435)
        }

        let unknown = UILabel()
        unknown.text = isAnalyzed ? "CYBER" : "? ? ?"
        unknown.textColor = .white
        unknown.textAlignment = .center
        unknown.font = KivroTypography.inter(size: 24, weight: .bold)
        panel.addSubview(unknown)
        unknown.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }

        let subtitle = UILabel()
        subtitle.text = "Your Persona Archetype"
        subtitle.textColor = UIColor(red: 183 / 255, green: 172 / 255, blue: 198 / 255, alpha: 1)
        subtitle.font = KivroTypography.inter(size: 14, weight: .regular)
        panel.addSubview(subtitle)
        subtitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(53)
            make.centerX.equalToSuperview()
        }

        let names = ["Cyber", "Mecha", "Anime", "Gothic", "Fantasy", "Period"]
        let colors: [UIColor] = [
            UIColor(red: 69 / 255, green: 176 / 255, blue: 1, alpha: 1),
            UIColor.yellow,
            UIColor(red: 136 / 255, green: 121 / 255, blue: 1, alpha: 1),
            UIColor(red: 1, green: 120 / 255, blue: 136 / 255, alpha: 1),
            UIColor(red: 44 / 255, green: 212 / 255, blue: 203 / 255, alpha: 1),
            UIColor(red: 76 / 255, green: 210 / 255, blue: 1, alpha: 1)
        ]

        for index in names.indices {
            let y = 86 + CGFloat(index) * 40
            let name = UILabel()
            name.text = names[index]
            name.textColor = UIColor(red: 190 / 255, green: 180 / 255, blue: 202 / 255, alpha: 1)
            name.font = KivroTypography.inter(size: 14, weight: .regular)
            panel.addSubview(name)
            name.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(18)
                make.top.equalToSuperview().offset(y)
            }

            let score = UILabel()
            let scoreValue = analyzedScores[index]
            score.text = isAnalyzed ? "\(scoreValue)%" : "0%"
            score.textColor = colors[index]
            score.font = KivroTypography.inter(size: 14, weight: .bold)
            panel.addSubview(score)
            score.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(92)
                make.top.equalToSuperview().offset(y)
            }

            let line = UIView()
            line.backgroundColor = UIColor(red: 117 / 255, green: 110 / 255, blue: 126 / 255, alpha: 1)
            line.layer.cornerRadius = 1.5
            panel.addSubview(line)
            line.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(18)
                make.top.equalToSuperview().offset(y + 23)
                make.height.equalTo(3)
            }
            if isAnalyzed {
                let progress = UIView()
                progress.backgroundColor = colors[index]
                progress.layer.cornerRadius = 1.5
                panel.addSubview(progress)
                progress.snp.makeConstraints { make in
                    make.leading.equalToSuperview().offset(18)
                    make.top.equalToSuperview().offset(y + 23)
                    make.width.equalTo(line).multipliedBy(CGFloat(scoreValue) / 100)
                    make.height.equalTo(3)
                }
            }
        }

        guard isAnalyzed else { return }
        finalizeLockedResultsBlurAnimator()
        let maskContainer = UIView()
        maskContainer.layer.cornerRadius = 14
        maskContainer.layer.cornerCurve = .continuous
        maskContainer.layer.shadowColor = UIColor.black.cgColor
        maskContainer.layer.shadowOpacity = 0.24
        maskContainer.layer.shadowRadius = 16
        maskContainer.layer.shadowOffset = .zero
        panel.addSubview(maskContainer)
        maskContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(5)
            make.top.equalToSuperview().offset(158)
            make.height.equalTo(166)
        }

        let backgroundBlur = UIVisualEffectView(effect: nil)
        backgroundBlur.layer.cornerRadius = 14
        backgroundBlur.layer.cornerCurve = .continuous
        backgroundBlur.clipsToBounds = true
        backgroundBlur.isUserInteractionEnabled = false
        maskContainer.addSubview(backgroundBlur)
        backgroundBlur.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        let blurAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear) {
            backgroundBlur.effect = UIBlurEffect(style: .dark)
        }
        blurAnimator.fractionComplete = 0.45
        lockedResultsBlurAnimator = blurAnimator

        self.lockedResultsMaskContainer = maskContainer

        let analyzing = UILabel()
        analyzing.text = "Analyzing facial structure & style fit..."
        analyzing.textColor = UIColor(red: 86 / 255, green: 140 / 255, blue: 1, alpha: 1)
        analyzing.font = KivroTypography.inter(size: 11, weight: .regular)
        contentView.addSubview(analyzing)
        analyzing.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(235)
        }

        let button = KivroGradientButton()
        button.setTitle("VIEW FULL PERSONA CARD", for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.78
        button.addTarget(self, action: #selector(showPersonaCard), for: .touchUpInside)
        contentView.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(33)
            make.top.equalToSuperview().offset(613)
            make.height.equalTo(60)
        }
        personaCardButton = button

        let costBadge = UIView()
        costBadge.backgroundColor = UIColor(red: 100 / 255, green: 91 / 255, blue: 1, alpha: 1)
        costBadge.layer.cornerRadius = 12
        contentView.addSubview(costBadge)
        costBadge.snp.makeConstraints { make in
            make.trailing.equalTo(button).inset(1)
            make.top.equalTo(button).offset(-7)
            make.width.equalTo(66)
            make.height.equalTo(24)
        }

        let coinImage = UIImageView(image: UIImage(named: "kivro_coin_badge"))
        coinImage.contentMode = .scaleAspectFit
        costBadge.addSubview(coinImage)
        coinImage.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(7)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        let priceLabel = UILabel()
        priceLabel.text = "300"
        priceLabel.textColor = .white
        priceLabel.font = KivroTypography.inter(size: 13, weight: .bold)
        priceLabel.textAlignment = .center
        costBadge.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.leading.equalTo(coinImage.snp.trailing).offset(2)
            make.trailing.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
        personaCardCostBadge = costBadge
        refreshPersonaCardButtonState()
    }

    private func refreshPersonaCardButtonState() {
        guard personaCardButton != nil else { return }
        let isUnlocked = KivroProductState.shared.isPersonaCardUnlocked(
            for: KivroSessionState.shared.currentUserIdentifier
        )
        personaCardCostBadge?.isHidden = isUnlocked
        lockedResultsMaskContainer?.isHidden = isUnlocked
    }

    private func finalizeLockedResultsBlurAnimator() {
        guard let animator = lockedResultsBlurAnimator else { return }
        if animator.state == .active {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .current)
        } else if animator.state == .inactive {
            animator.stopAnimation(true)
        }
        lockedResultsBlurAnimator = nil
    }

    @objc private func analyzePhoto() {
        KivroPhotoLibraryAccess.request(from: self) { [weak self] in
            self?.presentPhotoPicker()
        }
    }

    private func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        loadingOverlay.show(in: view)
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                guard let image = object as? UIImage else {
                    self.loadingOverlay.hide()
                    KivroToastPresenter.show(message: "Unable to read this photo.", in: self.view)
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                    self?.refreshAnalysis(with: image)
                }
            }
        }
    }

    private func refreshAnalysis(with image: UIImage) {
        isAnalyzed = true
        analyzedImage = image
        analyzedScores = Self.makeAnalyzedScores()
        KivroProductState.shared.lockPersonaCard(for: currentUserIdentifier)
        loadingOverlay.hide()
        view.subviews.forEach { $0.removeFromSuperview() }
        configureLayout()
    }

    @objc private func showPersonaCard() {
        guard KivroAccountAccess.requireAccount(from: self) else { return }
        guard !KivroProductState.shared.isPersonaCardUnlocked(for: currentUserIdentifier) else {
            navigationController?.pushViewController(makePersonaCardController(), animated: true)
            return
        }
        present(
            KivroConfirmationViewController(
                titleKey: "prompt.persona.title",
                messageKey: "prompt.persona.message",
                confirmKey: "common.confirm"
            ) { [weak self] in self?.completePersonaCardUnlock() },
            animated: true
        )
    }

    private func completePersonaCardUnlock() {
        guard KivroCoinWallet.shared.balance(for: currentUserIdentifier) >= personaCardUnlockPrice else {
            present(
                KivroConfirmationViewController(
                    titleKey: "prompt.coins.title",
                    messageKey: "prompt.coins.message",
                    confirmKey: "common.recharge"
                ) { [weak self] in
                    self?.navigationController?.pushViewController(RechargeViewController(), animated: true)
                },
                animated: true
            )
            return
        }
        guard loadingOverlay.superview == nil else { return }
        loadingOverlay.show(in: view)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let succeeded = KivroCoinWallet.shared.spend(
                personaCardUnlockPrice,
                for: currentUserIdentifier
            )
            loadingOverlay.hide()
            guard succeeded else {
                KivroToastPresenter.show(
                    message: "Unable to unlock Persona Card. Try again.",
                    in: view
                )
                return
            }
            KivroProductState.shared.unlockPersonaCard(for: currentUserIdentifier)
            refreshPersonaCardButtonState()
            navigationController?.pushViewController(makePersonaCardController(), animated: true)
        }
    }

    private func makePersonaCardController() -> PersonaCardViewController {
        PersonaCardViewController(scores: analyzedScores)
    }

    @objc private func closeScreen() {
        navigationController?.popViewController(animated: true)
    }
}
