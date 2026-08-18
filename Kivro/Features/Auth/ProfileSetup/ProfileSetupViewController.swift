import UIKit
import SnapKit
import PhotosUI

final class ProfileSetupViewController: KivroViewController,
                                       UITextFieldDelegate,
                                       PHPickerViewControllerDelegate,
                                       UIImagePickerControllerDelegate,
                                       UINavigationControllerDelegate,
                                       UIPickerViewDataSource,
                                       UIPickerViewDelegate {
    private var selectedGender = 0
    private var selectedBirthday: Date = Calendar.current.date(
        from: DateComponents(year: 1999, month: 1, day: 1)
    ) ?? Date()
    private var selectedCountryCode = "KY"
    private let countryCodes = Locale.isoRegionCodes
        .filter { $0.count == 2 }
        .sorted()
    private let nameField = KivroTextField(localizationKey: "profile.name_placeholder")
    private let avatarView = UIImageView(image: UIImage(named: "kivro_default_profile_avatar"))
    private let birthdayButton = UIButton(type: .system)
    private let countryButton = UIButton(type: .system)
    private let birthdayInput = UITextField()
    private let countryInput = UITextField()
    private let birthdayPicker = UIDatePicker()
    private let countryPicker = UIPickerView()
    private let manButton = UIButton(type: .custom)
    private let womanButton = UIButton(type: .custom)
    private let manLabel = UILabel()
    private let womanLabel = UILabel()
    private let loadingOverlay = KivroLoadingOverlay()
    private var selectedAvatar: UIImage? = UIImage(named: "kivro_default_profile_avatar")

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureInputPickers()
        configureLayout()
        updateGenderSelection()
        updateBirthdayText()
        updateCountryText()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 56
        view.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(84)
            make.size.equalTo(112)
        }

        let avatarButton = UIButton(type: .custom)
        avatarButton.accessibilityLabel = "Choose profile photo"
        avatarButton.addTarget(self, action: #selector(selectAvatar), for: .touchUpInside)
        view.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.edges.equalTo(avatarView)
        }

        let cameraButton = UIButton(type: .custom)
        cameraButton.accessibilityLabel = "Choose profile photo"
        cameraButton.addTarget(self, action: #selector(selectAvatar), for: .touchUpInside)
        view.addSubview(cameraButton)
        cameraButton.snp.makeConstraints { make in
            make.centerX.equalTo(avatarView)
            make.bottom.equalTo(avatarView).offset(8)
            make.size.equalTo(44)
        }

        let cameraImageView = UIImageView(image: UIImage(named: "kivro_camera_icon"))
        cameraImageView.contentMode = .scaleAspectFit
        cameraImageView.isUserInteractionEnabled = false
        cameraButton.addSubview(cameraImageView)
        cameraImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }

        let improve = UIImageView(image: UIImage(named: "kivro_profile_improve_title"))
        improve.contentMode = .scaleAspectFit
        view.addSubview(improve)
        improve.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(220)
            make.width.equalTo(214)
            make.height.equalTo(14)
        }

        nameField.delegate = self
        nameField.returnKeyType = .done
        view.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.top.equalToSuperview().offset(302)
            make.height.equalTo(48)
        }

        configureChoiceRow(birthdayButton, top: 377, action: #selector(showBirthdayPicker))
        configureChoiceRow(countryButton, top: 452, action: #selector(showCountryPicker))

        view.addSubview(birthdayInput)
        birthdayInput.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.bottom.equalToSuperview()
            make.size.equalTo(1)
        }

        view.addSubview(countryInput)
        countryInput.snp.makeConstraints { make in
            make.leading.equalTo(birthdayInput.snp.trailing)
            make.bottom.equalToSuperview()
            make.size.equalTo(1)
        }

        configureGenderButton(manButton, tag: 0, leading: 61)
        configureGenderButton(womanButton, tag: 1, leading: 235)
        configureGenderLabel(manLabel, titleKey: "profile.gender_man", centerX: 101)
        configureGenderLabel(womanLabel, titleKey: "profile.gender_woman", centerX: 275)

        let release = KivroGradientButton()
        release.setTitle("RELEASE", for: .normal)
        release.addTarget(self, action: #selector(releaseProfile), for: .touchUpInside)
        view.addSubview(release)
        release.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            make.top.equalToSuperview().offset(703)
            make.height.equalTo(60)
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

    private func configureChoiceRow(_ button: UIButton, top: CGFloat, action: Selector) {
        button.setTitleColor(UIColor.white.withAlphaComponent(0.55), for: .normal)
        button.titleLabel?.font = KivroTypography.inter(size: 13, weight: .regular)
        button.contentHorizontalAlignment = .left
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.top.equalToSuperview().offset(top)
            make.height.equalTo(48)
        }

        let chevron = UIImageView(image: UIImage(named: "kivro_chevron_right"))
        chevron.contentMode = .scaleAspectFit
        button.addSubview(chevron)
        chevron.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }

        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        button.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    private func configureInputPickers() {
        birthdayPicker.datePickerMode = .date
        birthdayPicker.preferredDatePickerStyle = .wheels
        birthdayPicker.maximumDate = Date()
        birthdayPicker.date = selectedBirthday
        birthdayInput.inputView = birthdayPicker
        birthdayInput.inputAccessoryView = makePickerToolbar(doneAction: #selector(finishBirthdaySelection))

        countryPicker.dataSource = self
        countryPicker.delegate = self
        countryInput.inputView = countryPicker
        countryInput.inputAccessoryView = makePickerToolbar(doneAction: #selector(finishCountrySelection))
        if let selectedRow = countryCodes.firstIndex(of: selectedCountryCode) {
            countryPicker.selectRow(selectedRow, inComponent: 0, animated: false)
        }
    }

    private func makePickerToolbar(doneAction: Selector) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: doneAction)
        ]
        return toolbar
    }

    private func configureGenderButton(_ button: UIButton, tag: Int, leading: CGFloat) {
        button.tag = tag
        button.layer.cornerRadius = 16
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.imageView?.contentMode = .scaleAspectFit
        button.imageEdgeInsets = UIEdgeInsets(top: 22, left: 22, bottom: 22, right: 22)
        button.addTarget(self, action: #selector(selectGender(_:)), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(leading)
            make.top.equalToSuperview().offset(524)
            make.size.equalTo(80)
        }
    }

    private func configureGenderLabel(_ label: UILabel, titleKey: String, centerX: CGFloat) {
        label.text = KivroStrings.value(titleKey)
        label.textColor = .white
        label.font = KivroTypography.inter(size: 12, weight: .bold)
        label.textAlignment = .center
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(centerX - 187.5)
            make.top.equalToSuperview().offset(615)
        }
    }

    private func updateGenderSelection() {
        manButton.setImage(
            UIImage(named: selectedGender == 0 ? "kivro_profile_gender_man_selected" : "kivro_profile_gender_man_unselected"),
            for: .normal
        )
        womanButton.setImage(
            UIImage(named: selectedGender == 1 ? "kivro_profile_gender_woman_selected" : "kivro_profile_gender_woman_unselected"),
            for: .normal
        )
        manButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        womanButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        manButton.alpha = 1
        womanButton.alpha = 1
        manLabel.textColor = UIColor.white.withAlphaComponent(selectedGender == 0 ? 1 : 0.45)
        womanLabel.textColor = UIColor.white.withAlphaComponent(selectedGender == 1 ? 1 : 0.45)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc private func showBirthdayPicker() {
        birthdayInput.becomeFirstResponder()
    }

    @objc private func showCountryPicker() {
        countryInput.becomeFirstResponder()
    }

    @objc private func finishBirthdaySelection() {
        selectedBirthday = birthdayPicker.date
        updateBirthdayText()
        birthdayInput.resignFirstResponder()
    }

    @objc private func finishCountrySelection() {
        let row = countryPicker.selectedRow(inComponent: 0)
        if countryCodes.indices.contains(row) {
            selectedCountryCode = countryCodes[row]
            updateCountryText()
        }
        countryInput.resignFirstResponder()
    }

    private func updateBirthdayText() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        birthdayButton.setTitle(formatter.string(from: selectedBirthday), for: .normal)
    }

    private func updateCountryText() {
        countryButton.setTitle(selectedCountryCode, for: .normal)
    }

    @objc private func selectAvatar() {
        let sourcePicker = UIAlertController(title: "Choose Profile Photo", message: nil, preferredStyle: .actionSheet)
        sourcePicker.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.selectAvatarFromLibrary()
        })
        sourcePicker.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.takeAvatarPhoto()
        })
        sourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sourcePicker.popoverPresentationController?.sourceView = view
        sourcePicker.popoverPresentationController?.sourceRect = CGRect(
            x: view.bounds.midX,
            y: view.bounds.midY,
            width: 1,
            height: 1
        )
        present(sourcePicker, animated: true)
    }

    private func selectAvatarFromLibrary() {
        KivroPhotoLibraryAccess.request(from: self) { [weak self] in
            self?.presentAvatarPicker()
        }
    }

    private func takeAvatarPhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            KivroToastPresenter.show(message: "Camera is unavailable on this device.", in: view)
            return
        }
        KivroCaptureAuthorization.request(mode: .photo, from: self) { [weak self] in
            self?.presentAvatarCamera()
        }
    }

    private func presentAvatarCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentAvatarPicker() {
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
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let self, let image = object as? UIImage else {
                    guard let self else { return }
                    KivroToastPresenter.show(message: "Unable to read this photo.", in: self.view)
                    return
                }
                self.applyAvatar(image)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else {
            KivroToastPresenter.show(message: "Unable to read this photo.", in: view)
            return
        }
        applyAvatar(image)
    }

    private func applyAvatar(_ image: UIImage) {
        selectedAvatar = image
        avatarView.image = image
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        countryCodes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard countryCodes.indices.contains(row) else { return nil }
        return countryCodes[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard countryCodes.indices.contains(row) else { return }
        selectedCountryCode = countryCodes[row]
        updateCountryText()
    }

    @objc private func selectGender(_ sender: UIButton) {
        selectedGender = sender.tag
        updateGenderSelection()
    }

    @objc private func releaseProfile() {
        view.endEditing(true)
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            KivroToastPresenter.show(message: KivroStrings.value("common.required"), in: view)
            return
        }
        guard let pendingRegistration = KivroSessionState.shared.pendingRegistration else {
            KivroToastPresenter.show(message: KivroStrings.value("auth.registration_expired"), in: view)
            return
        }
        loadingOverlay.show(in: view)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            guard let self else { return }
            do {
                let user = try KivroSeedDatabase.shared.registerUser(
                    identifier: pendingRegistration.identifier,
                    username: name,
                    gender: self.selectedGender == 0 ? "male" : "female",
                    birthday: self.selectedBirthday,
                    countryCode: self.selectedCountryCode,
                    avatarAssetName: "kivro_default_profile_avatar",
                    email: pendingRegistration.email,
                    password: pendingRegistration.password
                )
                KivroSessionState.shared.signIn(
                    email: user.email,
                    displayName: user.username,
                    identifier: user.identifier
                )
                _ = KivroProfileState.shared.saveProfile(
                    name: name,
                    avatar: self.selectedAvatar,
                    for: user.identifier
                )
                KivroSessionState.shared.clearPendingRegistration()
                self.loadingOverlay.hide()
                self.view.window?.rootViewController = KivroTabBarController()
            } catch KivroRegistrationError.duplicateEmail {
                self.loadingOverlay.hide()
                KivroToastPresenter.show(message: KivroStrings.value("auth.email_exists"), in: self.view)
            } catch {
                self.loadingOverlay.hide()
                KivroToastPresenter.show(
                    message: KivroStrings.value("auth.registration_failed"),
                    in: self.view
                )
            }
        }
    }
}
