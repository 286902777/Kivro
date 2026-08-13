import UIKit
import SnapKit

final class KivroRadarReplyViewController: KivroViewController,
                                                 UITextFieldDelegate,
                                                 UIGestureRecognizerDelegate {
    private let profile: KivroRadarProfile
    private let sheet = UIView()
    private let inputField = UITextField()
    private var sheetBottomConstraint: Constraint?
    private var isSending = false

    init(profile: KivroRadarProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayout()
        configureKeyboardHandling()
    }

    private func configureLayout() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.18)

        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 25
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(sheet)
        sheet.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(232)
            sheetBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        let avatar = UIImageView(image: UIImage(named: profile.avatarAssetName))
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 26
        sheet.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(23)
            make.top.equalToSuperview().offset(38)
            make.size.equalTo(52)
        }

        let nameLabel = UILabel()
        nameLabel.text = profile.name
        nameLabel.textColor = .black
        nameLabel.font = KivroTypography.inter(size: 16, weight: .bold)
        sheet.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(86)
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(39)
        }

        let copyLabel = UILabel()
        copyLabel.text = profile.radarCopy
        copyLabel.textColor = .black
        copyLabel.font = KivroTypography.inter(size: 11, weight: .regular)
        copyLabel.numberOfLines = 4
        copyLabel.lineBreakMode = .byTruncatingTail
        sheet.addSubview(copyLabel)
        copyLabel.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(62)
            make.height.lessThanOrEqualTo(56)
        }

        let moreButton = UIButton(type: .system)
        moreButton.setTitle("··· More", for: .normal)
        moreButton.setTitleColor(UIColor.black.withAlphaComponent(0.42), for: .normal)
        moreButton.titleLabel?.font = KivroTypography.inter(size: 11, weight: .regular)
        moreButton.contentHorizontalAlignment = .left
        moreButton.addTarget(self, action: #selector(showMore), for: .touchUpInside)
        sheet.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.leading.equalTo(nameLabel)
            make.top.equalToSuperview().offset(117)
            make.width.equalTo(72)
            make.height.equalTo(28)
        }

        let divider = UIView()
        divider.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        sheet.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(159)
            make.height.equalTo(1)
        }

        let composeIcon = UIImageView(image: UIImage(named: "kivro_compose_icon"))
        composeIcon.contentMode = .scaleAspectFit
        sheet.addSubview(composeIcon)
        composeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(17)
            make.top.equalTo(divider.snp.bottom).offset(22)
            make.size.equalTo(16)
        }

        inputField.placeholder = "Say something..."
        inputField.textColor = .black
        inputField.tintColor = .black
        inputField.font = KivroTypography.inter(size: 14, weight: .regular)
        inputField.returnKeyType = .send
        inputField.delegate = self
        sheet.addSubview(inputField)
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(44)
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(composeIcon)
            make.height.equalTo(42)
        }

        let indicator = UIView()
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = 2.5
        sheet.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    private func configureKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendReply()
        return false
    }

    @objc private func showMore() {
        guard profile.identifier != KivroSessionState.shared.currentUserIdentifier else { return }
        present(
            MoreActionsViewController(
                targetUserIdentifier: profile.identifier,
                currentUserIdentifier: KivroSessionState.shared.currentUserIdentifier
            ),
            animated: true
        )
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        touch.view !== inputField
    }

    private func sendReply() {
        guard !isSending else { return }
        guard let reply = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !reply.isEmpty else {
            KivroToastPresenter.show(message: "Enter a reply.", in: view)
            return
        }
        isSending = true
        inputField.text = nil
        inputField.resignFirstResponder()
        KivroToastPresenter.show(message: "Reply sent.", in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isSending = false
        }
    }

    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        if inputField.isFirstResponder {
            inputField.resignFirstResponder()
            return
        }
        guard gesture.location(in: view).y < sheet.frame.minY else { return }
        dismiss(animated: true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let convertedFrame = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - convertedFrame.minY)
        sheetBottomConstraint?.update(offset: -overlap)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16)
        ) {
            self.view.layoutIfNeeded()
        }
    }
}
