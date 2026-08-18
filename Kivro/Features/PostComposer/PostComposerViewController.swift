import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers

final class PostComposerViewController: KivroViewController,
                                        UITextViewDelegate,
                                        PHPickerViewControllerDelegate,
                                        UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate {
    private let captionView = UITextView()
    private let previewImageView = UIImageView()
    private let uploadIcon = UIImageView(image: UIImage(named: "kivro_add_photo_icon"))
    private let uploadLabel = UILabel()
    private let loadingOverlay = KivroLoadingOverlay()
    private let categories = ["Anime", "Cyber", "Fantasy", "Gothic", "Mecha", "Period"]
    private var categoryButtons: [UIButton] = []
    private var selectedCategory = "Anime"
    private var selectedMediaImage: UIImage?
    private var selectedMediaIsVideo = false
    private var selectedVideoURL: URL?
    private var videoPlayOverlay: UIImageView?
    private var publishBottomConstraint: Constraint?
    private var isPublishing = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        configureLayout()
        configureKeyboardHandling()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { $0.edges.equalToSuperview() }

        let header = KivroPageHeaderView(title: "Create Post")
        header.onBack = { [weak self] in self?.navigationController?.popViewController(animated: true) }
        view.addSubview(header)
        header.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(105)
        }

        let upload = UIButton(type: .custom)
        upload.backgroundColor = UIColor.white.withAlphaComponent(0.03)
        upload.layer.cornerRadius = 22
        upload.layer.borderWidth = 1.5
        upload.layer.borderColor = UIColor.white.withAlphaComponent(0.65).cgColor
        upload.clipsToBounds = true
        upload.addTarget(self, action: #selector(selectMedia), for: .touchUpInside)
        view.addSubview(upload)
        upload.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(139)
            make.width.equalTo(169)
            make.height.equalTo(246)
        }

        previewImageView.contentMode = .scaleAspectFill
        previewImageView.clipsToBounds = true
        previewImageView.isHidden = true
        upload.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in make.edges.equalToSuperview() }

        uploadIcon.contentMode = .scaleAspectFit
        upload.addSubview(uploadIcon)
        uploadIcon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(65)
            make.size.equalTo(64)
        }

        uploadLabel.text = "Upload Videos &\nPhotos"
        uploadLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        uploadLabel.textAlignment = .center
        uploadLabel.numberOfLines = 2
        uploadLabel.font = KivroTypography.inter(size: 13, weight: .regular)
        upload.addSubview(uploadLabel)
        uploadLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(153)
        }

        configureCategoryPicker()

        captionView.text = "Write a caption..."
        captionView.textColor = UIColor.white.withAlphaComponent(0.55)
        captionView.backgroundColor = .clear
        captionView.font = KivroTypography.inter(size: 13, weight: .regular)
        captionView.textContainerInset = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        captionView.textContainer.lineFragmentPadding = 0
        captionView.returnKeyType = .done
        captionView.delegate = self
        view.addSubview(captionView)
        captionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(31)
            make.top.equalToSuperview().offset(460)
            make.height.equalTo(90)
        }

        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.55)
        view.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(31)
            make.top.equalToSuperview().offset(549)
            make.height.equalTo(1)
        }

        let publish = KivroGradientButton()
        publish.setTitle("PUBLISH", for: .normal)
        publish.addTarget(self, action: #selector(publishPost), for: .touchUpInside)
        view.addSubview(publish)
        publish.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            make.height.equalTo(60)
            publishBottomConstraint = make.bottom.equalTo(view.safeAreaLayoutGuide).inset(30).constraint
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

    private func configureCategoryPicker() {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(31)
            make.top.equalToSuperview().offset(418)
            make.height.equalTo(30)
        }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        scrollView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }

        categoryButtons = categories.enumerated().map { index, title in
            let button = UIButton(type: .system)
            button.tag = index
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = KivroTypography.inter(size: 12, weight: .bold)
            button.layer.cornerRadius = 15
            button.addTarget(self, action: #selector(selectCategory(_:)), for: .touchUpInside)
            button.snp.makeConstraints { make in
                make.width.equalTo(max(58, title.count * 9 + 24))
                make.height.equalTo(30)
            }
            stack.addArrangedSubview(button)
            return button
        }
        updateCategoryButtons()
    }

    private func configureKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    private func updateCategoryButtons() {
        for (index, button) in categoryButtons.enumerated() {
            button.backgroundColor = categories[index] == selectedCategory
                ? UIColor(red: 139 / 255, green: 31 / 255, blue: 213 / 255, alpha: 1)
                : UIColor.white.withAlphaComponent(0.25)
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Write a caption..." {
            textView.text = nil
            textView.textColor = .white
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Write a caption..."
            textView.textColor = UIColor.white.withAlphaComponent(0.55)
        }
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }

    @objc private func selectMedia() {
        view.endEditing(true)
        let sourcePicker = UIAlertController(title: "Add Media", message: nil, preferredStyle: .actionSheet)
        sourcePicker.addAction(UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
            self?.selectMediaFromLibrary()
        })
        sourcePicker.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.selectMediaFromCamera(mode: .photo)
        })
        sourcePicker.addAction(UIAlertAction(title: "Record Video", style: .default) { [weak self] _ in
            self?.selectMediaFromCamera(mode: .video)
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

    private func selectMediaFromLibrary() {
        KivroPhotoLibraryAccess.request(from: self) { [weak self] in
            self?.presentMediaPicker()
        }
    }

    private func selectMediaFromCamera(mode: KivroCaptureAuthorization.Mode) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            KivroToastPresenter.show(message: "Camera is unavailable on this device.", in: view)
            return
        }
        KivroCaptureAuthorization.request(mode: mode, from: self) { [weak self] in
            self?.presentCamera(mode: mode)
        }
    }

    private func presentCamera(mode: KivroCaptureAuthorization.Mode) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = false
        switch mode {
        case .photo:
            picker.mediaTypes = [UTType.image.identifier]
            picker.cameraCaptureMode = .photo
        case .video:
            picker.mediaTypes = [UTType.movie.identifier]
            picker.cameraCaptureMode = .video
            picker.videoQuality = .typeHigh
            picker.videoMaximumDuration = 60
        }
        present(picker, animated: true)
    }

    private func presentMediaPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .any(of: [.images, .videos])
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else { return }

        if provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            loadingOverlay.show(in: view)
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                guard let self else { return }
                guard let url else {
                    DispatchQueue.main.async {
                        self.loadingOverlay.hide()
                        KivroToastPresenter.show(message: "Unable to read this video.", in: self.view)
                    }
                    return
                }
                let persistedURL: URL
                do {
                    persistedURL = try KivroVideoMedia.shared.persistPickedVideo(from: url)
                } catch {
                    DispatchQueue.main.async {
                        self.loadingOverlay.hide()
                        KivroToastPresenter.show(message: "Unable to save this video.", in: self.view)
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.finishVideoSelection(with: persistedURL)
                }
            }
            return
        }

        guard provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let self, let image = object as? UIImage else { return }
                self.applySelectedMedia(image: image, isVideo: false, videoURL: nil)
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
        let mediaType = info[.mediaType] as? String
        if mediaType == UTType.movie.identifier, let sourceURL = info[.mediaURL] as? URL {
            loadingOverlay.show(in: view)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self else { return }
                do {
                    let persistedURL = try KivroVideoMedia.shared.persistPickedVideo(from: sourceURL)
                    DispatchQueue.main.async {
                        self.finishVideoSelection(with: persistedURL)
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.loadingOverlay.hide()
                        KivroToastPresenter.show(message: "Unable to save this video.", in: self.view)
                    }
                }
            }
            return
        }
        guard let image = info[.originalImage] as? UIImage else {
            KivroToastPresenter.show(message: "Unable to read this photo.", in: view)
            return
        }
        applySelectedMedia(image: image, isVideo: false, videoURL: nil)
    }

    private func finishVideoSelection(with videoURL: URL) {
        KivroVideoMedia.shared.thumbnail(for: videoURL) { [weak self] image in
            guard let self else { return }
            self.loadingOverlay.hide()
            guard let image else {
                KivroToastPresenter.show(message: "Unable to read this video.", in: self.view)
                return
            }
            self.applySelectedMedia(image: image, isVideo: true, videoURL: videoURL)
        }
    }

    private func applySelectedMedia(image: UIImage, isVideo: Bool, videoURL: URL?) {
        videoPlayOverlay?.removeFromSuperview()
        videoPlayOverlay = nil
        selectedMediaImage = image
        selectedMediaIsVideo = isVideo
        selectedVideoURL = videoURL
        previewImageView.image = image
        previewImageView.isHidden = false
        uploadIcon.isHidden = true
        uploadLabel.isHidden = true

        if isVideo {
            let play = UIImageView(image: UIImage(named: "kivro_video_play"))
            play.contentMode = .scaleAspectFit
            previewImageView.superview?.addSubview(play)
            play.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(58)
            }
            videoPlayOverlay = play
        }
    }

    @objc private func publishPost() {
        guard !isPublishing else { return }
        let text = captionView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let selectedMediaImage, !text.isEmpty, text != "Write a caption..." else {
            KivroToastPresenter.show(message: "Add media and a caption before publishing.", in: view)
            return
        }
        if selectedMediaIsVideo, selectedVideoURL == nil {
            KivroToastPresenter.show(message: "Video unavailable.", in: view)
            return
        }

        view.endEditing(true)
        isPublishing = true
        loadingOverlay.show(in: view)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            do {
                let mediaURL: URL
                if selectedMediaIsVideo, let selectedVideoURL {
                    mediaURL = selectedVideoURL
                } else {
                    mediaURL = try KivroVideoMedia.shared.persistImage(selectedMediaImage)
                }
                try KivroSeedDatabase.shared.addPost(
                    authorIdentifier: KivroSessionState.shared.currentUserIdentifier,
                    category: selectedCategory,
                    mediaAssetName: mediaURL.path,
                    body: text,
                    isVideo: selectedMediaIsVideo
                )
                loadingOverlay.hide()
                isPublishing = false
                navigationController?.popViewController(animated: true)
            } catch {
                loadingOverlay.hide()
                isPublishing = false
                KivroToastPresenter.show(message: "Unable to publish this post.", in: view)
            }
        }
    }

    @objc private func selectCategory(_ sender: UIButton) {
        selectedCategory = categories[sender.tag]
        updateCategoryButtons()
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let convertedFrame = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - convertedFrame.minY)
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        publishBottomConstraint?.update(inset: overlap > 0 ? overlap + 12 : 30)
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
}
