import UIKit
import SnapKit
import PhotosUI

final class EditProfileViewController: KivroViewController,
                                       UITextFieldDelegate,
                                       PHPickerViewControllerDelegate,
                                       UIImagePickerControllerDelegate,
                                       UINavigationControllerDelegate {
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private let nameField = KivroTextField(localizationKey: "profile.name_placeholder")
    private let avatarView = UIImageView()
    private let loadingOverlay = KivroLoadingOverlay()
    private let saveButton = KivroGradientButton()
    private let contentScrollView = UIScrollView()
    private let contentView = UIView()
    private var selectedAvatar: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = KivroPageHeaderView(title: "Edit Profile")
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        saveButton.setTitle("SAVE", for: .normal)
        saveButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(37).priority(.high)
            make.width.lessThanOrEqualTo(356)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(60)
        }

        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.alwaysBounceVertical = false
        contentScrollView.contentInsetAdjustmentBehavior = .never
        view.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(saveButton.snp.top).offset(-16)
        }
        contentScrollView.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.bottom.equalTo(contentScrollView.contentLayoutGuide)
            make.centerX.equalTo(contentScrollView.frameLayoutGuide)
            make.width.equalTo(contentScrollView.frameLayoutGuide).priority(.high)
            make.width.lessThanOrEqualTo(430)
            make.height.equalTo(335)
        }

        avatarView.image = KivroProfileState.shared.resolvedAvatar(for: currentUserIdentifier)
            ?? UIImage(named: "kivro_profile_editor_avatar")
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 56
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(39)
            make.size.equalTo(112)
        }

        let avatarButton = UIButton(type: .custom)
        avatarButton.accessibilityLabel = "Choose profile photo"
        avatarButton.addTarget(self, action: #selector(selectAvatar), for: .touchUpInside)
        contentView.addSubview(avatarButton)
        avatarButton.snp.makeConstraints { make in
            make.edges.equalTo(avatarView)
        }

        let cameraButton = UIButton(type: .custom)
        cameraButton.accessibilityLabel = "Choose profile photo"
        cameraButton.addTarget(self, action: #selector(selectAvatar), for: .touchUpInside)
        contentView.addSubview(cameraButton)
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
        contentView.addSubview(improve)
        improve.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(175)
            make.width.equalTo(215)
            make.height.equalTo(16)
        }

        nameField.delegate = self
        nameField.returnKeyType = .done
        nameField.text = KivroProfileState.shared.resolvedName(for: currentUserIdentifier)
        contentView.addSubview(nameField)
        nameField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(34)
            make.top.equalToSuperview().offset(257)
            make.height.equalTo(48)
        }

        let indicator = UIView()
        indicator.backgroundColor = .black
        indicator.layer.cornerRadius = 2.5
        view.addSubview(indicator)
        indicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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

    @objc private func saveProfile() {
        view.endEditing(true)
        guard let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            KivroToastPresenter.show(message: KivroStrings.value("common.required"), in: view)
            return
        }
        loadingOverlay.show(in: view)
        saveButton.isEnabled = false
        let avatar = selectedAvatar
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let succeeded = KivroProfileState.shared.saveProfile(
                name: name,
                avatar: avatar,
                for: self.currentUserIdentifier
            )
            DispatchQueue.main.async {
                self.loadingOverlay.hide()
                self.saveButton.isEnabled = true
                guard succeeded else {
                    KivroToastPresenter.show(message: "Unable to save your profile.", in: self.view)
                    return
                }
                self.navigationController?.popViewController(animated: true)
                if let toastContainer = self.navigationController?.view ?? self.view {
                    KivroToastPresenter.show(message: "Profile saved.", in: toastContainer)
                }
            }
        }
    }
}
