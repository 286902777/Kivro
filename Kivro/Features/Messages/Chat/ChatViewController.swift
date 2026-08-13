import UIKit
import SnapKit
import PhotosUI
import AVFoundation

final class ChatViewController: KivroViewController,
                                UITextFieldDelegate,
                                UITableViewDataSource,
                                UITableViewDelegate,
                                PHPickerViewControllerDelegate,
                                AVAudioPlayerDelegate,
                                AVSpeechSynthesizerDelegate,
                                UIGestureRecognizerDelegate {
    private let targetUserIdentifier: String
    private var currentUserIdentifier: String { KivroSessionState.shared.currentUserIdentifier }
    private var targetUser: KivroStoredUser? {
        KivroSeedDatabase.shared.user(identifier: targetUserIdentifier)
    }
    private let conversationTableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let inputField = UITextField()
    private let photoButton = UIButton(type: .custom)
    private let voiceButton = UIButton(type: .custom)
    private let speechSynthesizer = AVSpeechSynthesizer()

    private var messages: [KivroChatMessage] = []
    private var latestMessageDate: Date?

    private var inputBottomConstraint: Constraint?
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingURL: URL?
    private var recordingTimer: Timer?
    private weak var recordingView: KivroVoiceRecordingView?
    private var playingMessageIdentifier: UUID?
    private var isVoicePressActive = false
    private var isSending = false
    private var didPresentQAMoreSheet = false
    private var didAppendQAVoiceMessage = false

    init(targetUserIdentifier: String = "freja") {
        self.targetUserIdentifier = targetUserIdentifier
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Storyboard initialization is unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        guard KivroSeedDatabase.shared.canChat(
            between: currentUserIdentifier,
            and: targetUserIdentifier
        ) else {
            KivroToastPresenter.show(
                message: KivroStrings.value("social.chat_requires_mutual"),
                in: view
            )
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            return
        }
        speechSynthesizer.delegate = self
        loadStoredMessages()
        configureLayout()
        configureDismissKeyboardGesture()
        observeKeyboard()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        conversationTableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
#if DEBUG
        let qaScreen = ProcessInfo.processInfo.environment["KIVRO_QA_SCREEN"]
        if qaScreen == "chat_voice", !didAppendQAVoiceMessage {
            didAppendQAVoiceMessage = true
            appendMessage(
                KivroChatMessage(
                    senderIdentifier: currentUserIdentifier,
                    sender: .currentUser,
                    content: .voice(url: nil, duration: 4, spokenText: "Voice preview")
                )
            )
        }
        if qaScreen == "more", !didPresentQAMoreSheet {
            didPresentQAMoreSheet = true
            showMore()
        }
#endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if audioRecorder != nil {
            finishRecording(shouldSend: false)
        }
        stopPlayback()
    }

    private func configureLayout() {
        let background = KivroGradientView()
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        configureHeader()
        configureInputBar()
        configureConversation()
    }

    private func configureHeader() {
        let backButton = KivroBackButton()
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(54)
            make.size.equalTo(40)
        }

        let avatar = UIButton(type: .custom)
        avatar.setImage(
            KivroProfileState.shared.resolvedAvatar(for: targetUserIdentifier)
                ?? UIImage(named: targetUser?.avatarAssetName ?? "kivro_profile_header_avatar"),
            for: .normal
        )
        avatar.imageView?.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 38
        avatar.accessibilityLabel = "Open user profile"
        avatar.addTarget(self, action: #selector(openTargetProfile), for: .touchUpInside)
        view.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(54)
            make.size.equalTo(76)
        }

        if targetUserIdentifier != currentUserIdentifier {
            let moreButton = circleButton(imageName: "ellipsis", action: #selector(showMore))
            view.addSubview(moreButton)
            moreButton.snp.makeConstraints { make in
                make.trailing.equalToSuperview().inset(16)
                make.top.equalToSuperview().offset(54)
                make.size.equalTo(40)
            }
        }

        let nameLabel = UILabel()
        nameLabel.text = KivroProfileState.shared.resolvedName(for: targetUserIdentifier)
        nameLabel.textColor = .white
        nameLabel.font = KivroTypography.inter(size: 24, weight: .bold)
        view.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(141)
        }

        let timeLabel = UILabel()
        if let latestMessageDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "HH:mm"
            timeLabel.text = formatter.string(from: latestMessageDate)
        } else {
            timeLabel.text = nil
        }
        timeLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        timeLabel.font = KivroTypography.inter(size: 14, weight: .regular)
        view.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(175)
        }
    }

    private func configureConversation() {
        conversationTableView.backgroundColor = .clear
        conversationTableView.separatorStyle = .none
        conversationTableView.showsVerticalScrollIndicator = false
        conversationTableView.keyboardDismissMode = .interactive
        conversationTableView.rowHeight = UITableView.automaticDimension
        conversationTableView.estimatedRowHeight = 80
        conversationTableView.contentInset = UIEdgeInsets(top: 2, left: 0, bottom: 10, right: 0)
        conversationTableView.dataSource = self
        conversationTableView.delegate = self
        conversationTableView.register(
            KivroChatMessageCell.self,
            forCellReuseIdentifier: KivroChatMessageCell.reuseIdentifier
        )
        view.insertSubview(conversationTableView, belowSubview: inputBar)
        conversationTableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(199)
            make.bottom.equalTo(inputBar.snp.top)
        }
    }

    private func configureInputBar() {
        inputBar.backgroundColor = .white
        view.addSubview(inputBar)
        inputBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(74)
            inputBottomConstraint = make.bottom.equalToSuperview().constraint
        }

        let composeIcon = UIImageView(image: UIImage(named: "kivro_compose_icon"))
        composeIcon.contentMode = .scaleAspectFit
        inputBar.addSubview(composeIcon)
        composeIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(21)
            make.size.equalTo(18)
        }

        let voiceIcon = UIImageView(image: UIImage(named: "kivro_chat_voice_icon"))
        voiceIcon.contentMode = .scaleAspectFit
        voiceButton.addSubview(voiceIcon)
        voiceIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(22)
        }
        voiceButton.accessibilityLabel = "Hold to record"
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleVoicePress(_:)))
        longPress.minimumPressDuration = 0.15
        voiceButton.addGestureRecognizer(longPress)
        inputBar.addSubview(voiceButton)
        voiceButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(7)
            make.top.equalToSuperview().offset(7)
            make.size.equalTo(44)
        }

        let photoIcon = UIImageView(image: UIImage(named: "kivro_chat_photo_icon"))
        photoIcon.contentMode = .scaleAspectFit
        photoButton.addSubview(photoIcon)
        photoIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(20)
        }
        photoButton.accessibilityLabel = "Choose photo"
        photoButton.addTarget(self, action: #selector(selectPhoto), for: .touchUpInside)
        inputBar.addSubview(photoButton)
        photoButton.snp.makeConstraints { make in
            make.trailing.equalTo(voiceButton.snp.leading).offset(-1)
            make.top.equalToSuperview().offset(7)
            make.size.equalTo(44)
        }

        inputField.placeholder = "Say something..."
        inputField.textColor = .black
        inputField.font = KivroTypography.inter(size: 14, weight: .regular)
        inputField.returnKeyType = .send
        inputField.clearButtonMode = .whileEditing
        inputField.delegate = self
        inputBar.addSubview(inputField)
        inputField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(44)
            make.trailing.equalTo(photoButton.snp.leading).offset(-4)
            make.top.equalToSuperview().offset(10)
            make.height.equalTo(40)
        }

        let homeIndicator = UIView()
        homeIndicator.backgroundColor = .black
        homeIndicator.layer.cornerRadius = 2.5
        inputBar.addSubview(homeIndicator)
        homeIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(8)
            make.width.equalTo(134)
            make.height.equalTo(5)
        }
    }

    private func configureDismissKeyboardGesture() {
        view.gestureRecognizers?
            .compactMap { $0 as? UITapGestureRecognizer }
            .forEach { view.removeGestureRecognizer($0) }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(chatBackgroundTapped))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }

    private func circleButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: imageName), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func observeKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: KivroChatMessageCell.reuseIdentifier,
            for: indexPath
        ) as? KivroChatMessageCell else {
            return UITableViewCell()
        }
        let message = messages[indexPath.row]
        cell.configure(
            with: message,
            isPlaying: playingMessageIdentifier == message.identifier
        )
        cell.onAvatar = { [weak self] in
            guard message.sender == .otherUser else { return }
            self?.openUserProfile(identifier: message.senderIdentifier)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        switch message.content {
        case .image(let image):
            let preview = KivroImagePreviewViewController(image: image)
            navigationController?.pushViewController(preview, animated: true)
        case .voice:
            playVoiceMessage(message)
        case .text:
            break
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTextMessage()
        return false
    }

    private func sendTextMessage() {
        guard !isSending else { return }
        let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else {
            KivroToastPresenter.show(message: "Enter a message", in: view)
            return
        }

        isSending = true
        do {
            let storedMessage = try KivroSeedDatabase.shared.addChatMessage(
                senderIdentifier: currentUserIdentifier,
                recipientIdentifier: targetUserIdentifier,
                body: text
            )
            latestMessageDate = storedMessage.createdAt
            appendMessage(
                KivroChatMessage(
                    identifier: UUID(uuidString: storedMessage.identifier) ?? UUID(),
                    senderIdentifier: storedMessage.senderIdentifier,
                    sender: .currentUser,
                    content: .text(text)
                )
            )
            inputField.text = nil
            inputField.resignFirstResponder()
        } catch {
            KivroToastPresenter.show(message: "Unable to send message.", in: view)
        }
        isSending = false
    }

    private func loadStoredMessages() {
        let storedMessages = KivroSeedDatabase.shared.chatMessages(
            between: currentUserIdentifier,
            and: targetUserIdentifier
        )
        latestMessageDate = storedMessages.last?.createdAt
        messages = storedMessages.compactMap { makeViewMessage(from: $0) }
    }

    private func makeViewMessage(from storedMessage: KivroStoredChatMessage) -> KivroChatMessage? {
        let content: KivroMessageContent
        switch storedMessage.contentType {
        case "image":
            guard let data = storedMessage.mediaData,
                  let image = UIImage(data: data) else { return nil }
            content = .image(image)
        case "voice":
            let audioURL = storedMessage.mediaData.flatMap {
                cachedAudioURL(identifier: storedMessage.identifier, data: $0)
            }
            content = .voice(url: audioURL, duration: storedMessage.duration, spokenText: nil)
        default:
            content = .text(storedMessage.body)
        }
        return KivroChatMessage(
            identifier: UUID(uuidString: storedMessage.identifier) ?? UUID(),
            senderIdentifier: storedMessage.senderIdentifier,
            sender: storedMessage.senderIdentifier == currentUserIdentifier ? .currentUser : .otherUser,
            content: content
        )
    }

    private func cachedAudioURL(identifier: String, data: Data) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kivro_chat_\(identifier)")
            .appendingPathExtension("m4a")
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try data.write(to: url, options: .atomic)
            }
            return url
        } catch {
            return nil
        }
    }

    private func appendMessage(_ message: KivroChatMessage) {
        messages.append(message)
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        conversationTableView.performBatchUpdates {
            conversationTableView.insertRows(at: [indexPath], with: .fade)
        } completion: { [weak self] _ in
            self?.conversationTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }

    @objc private func selectPhoto() {
        inputField.resignFirstResponder()
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        photoButton.isEnabled = false
        present(picker, animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider else {
            photoButton.isEnabled = true
            return
        }
        guard provider.canLoadObject(ofClass: UIImage.self) else {
            photoButton.isEnabled = true
            KivroToastPresenter.show(message: "Photo unavailable", in: view)
            return
        }

        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.photoButton.isEnabled = true
                guard let image = object as? UIImage else {
                    KivroToastPresenter.show(message: "Photo unavailable", in: self.view)
                    return
                }
                guard let imageData = image.jpegData(compressionQuality: 0.82) else {
                    KivroToastPresenter.show(message: "Photo unavailable", in: self.view)
                    return
                }
                do {
                    let storedMessage = try KivroSeedDatabase.shared.addImageChatMessage(
                        senderIdentifier: self.currentUserIdentifier,
                        recipientIdentifier: self.targetUserIdentifier,
                        imageData: imageData
                    )
                    self.latestMessageDate = storedMessage.createdAt
                    if let message = self.makeViewMessage(from: storedMessage) {
                        self.appendMessage(message)
                    }
                } catch {
                    KivroToastPresenter.show(message: "Unable to send photo.", in: self.view)
                }
            }
        }
    }

    @objc private func handleVoicePress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            isVoicePressActive = true
            inputField.resignFirstResponder()
            requestRecordingPermission()
        case .ended:
            isVoicePressActive = false
            finishRecording(shouldSend: true)
        case .cancelled, .failed:
            isVoicePressActive = false
            finishRecording(shouldSend: false)
        default:
            break
        }
    }

    private func requestRecordingPermission() {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            startRecordingIfNeeded()
        case .denied:
            isVoicePressActive = false
            KivroToastPresenter.show(message: "Microphone access is required", in: view)
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard granted else {
                        self.isVoicePressActive = false
                        KivroToastPresenter.show(message: "Microphone access is required", in: self.view)
                        return
                    }
                    self.startRecordingIfNeeded()
                }
            }
        @unknown default:
            isVoicePressActive = false
            KivroToastPresenter.show(message: "Microphone unavailable", in: view)
        }
    }

    private func startRecordingIfNeeded() {
        guard isVoicePressActive, audioRecorder == nil else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kivro_voice_\(UUID().uuidString)")
            .appendingPathExtension("m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.prepareToRecord(), recorder.record() else {
                throw CocoaError(.fileWriteUnknown)
            }
            recordingURL = url
            audioRecorder = recorder
            presentRecordingView()
            startRecordingTimer()
        } catch {
            isVoicePressActive = false
            KivroToastPresenter.show(message: "Unable to record audio", in: view)
        }
    }

    private func presentRecordingView() {
        let recordingView = KivroVoiceRecordingView()
        view.addSubview(recordingView)
        recordingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(168)
        }
        self.recordingView = recordingView
        recordingView.presentAnimated()
    }

    private func startRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let recorder = self.audioRecorder else { return }
            self.recordingView?.updateDuration(recorder.currentTime)
        }
    }

    private func finishRecording(shouldSend: Bool) {
        guard let recorder = audioRecorder else { return }
        let duration = recorder.currentTime
        recorder.stop()
        audioRecorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingView?.dismissAnimated()

        guard let url = recordingURL else { return }
        recordingURL = nil
        guard shouldSend, duration >= 0.4 else {
            try? FileManager.default.removeItem(at: url)
            if shouldSend {
                KivroToastPresenter.show(message: "Hold longer to record", in: view)
            }
            return
        }

        do {
            let audioData = try Data(contentsOf: url)
            let storedMessage = try KivroSeedDatabase.shared.addVoiceChatMessage(
                senderIdentifier: currentUserIdentifier,
                recipientIdentifier: targetUserIdentifier,
                audioData: audioData,
                duration: duration
            )
            latestMessageDate = storedMessage.createdAt
            appendMessage(
                KivroChatMessage(
                    identifier: UUID(uuidString: storedMessage.identifier) ?? UUID(),
                    senderIdentifier: storedMessage.senderIdentifier,
                    sender: .currentUser,
                    content: .voice(url: url, duration: duration, spokenText: nil)
                )
            )
        } catch {
            try? FileManager.default.removeItem(at: url)
            KivroToastPresenter.show(message: "Unable to send audio.", in: view)
        }
    }

    private func playVoiceMessage(_ message: KivroChatMessage) {
        guard case .voice(let url, _, let spokenText) = message.content else { return }
        if playingMessageIdentifier == message.identifier {
            stopPlayback()
            return
        }

        stopPlayback()
        playingMessageIdentifier = message.identifier
        conversationTableView.reloadData()

        if let url {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default)
                try session.setActive(true)
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = self
                player.prepareToPlay()
                guard player.play() else {
                    throw CocoaError(.fileReadUnknown)
                }
                audioPlayer = player
            } catch {
                stopPlayback()
                KivroToastPresenter.show(message: "Unable to play audio", in: view)
            }
        } else if let spokenText {
            let utterance = AVSpeechUtterance(string: spokenText)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.46
            speechSynthesizer.speak(utterance)
        } else {
            stopPlayback()
            KivroToastPresenter.show(message: "Audio unavailable", in: view)
        }
    }

    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        guard playingMessageIdentifier != nil else { return }
        playingMessageIdentifier = nil
        conversationTableView.reloadData()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        playingMessageIdentifier = nil
        conversationTableView.reloadData()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        playingMessageIdentifier = nil
        conversationTableView.reloadData()
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: inputField)
    }

    @objc private func chatBackgroundTapped() {
        view.endEditing(true)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else { return }
        let converted = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - converted.minY)
        inputBottomConstraint?.update(offset: -overlap)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: UIView.AnimationOptions(rawValue: curveValue << 16)
        ) {
            self.view.layoutIfNeeded()
            self.scrollToLatestMessage(animated: false)
        }
    }

    private func scrollToLatestMessage(animated: Bool) {
        guard !messages.isEmpty else { return }
        conversationTableView.scrollToRow(
            at: IndexPath(row: messages.count - 1, section: 0),
            at: .bottom,
            animated: animated
        )
    }

    @objc private func showMore() {
        guard targetUserIdentifier != currentUserIdentifier else { return }
        present(
            MoreActionsViewController(
                targetUserIdentifier: targetUserIdentifier,
                currentUserIdentifier: currentUserIdentifier
            ),
            animated: true
        )
    }

    @objc private func openTargetProfile() {
        openUserProfile(identifier: targetUserIdentifier)
    }

    private func openUserProfile(identifier: String) {
        guard identifier != currentUserIdentifier else { return }
        guard KivroSeedDatabase.shared.user(identifier: identifier) != nil else {
            KivroToastPresenter.show(message: "Unable to load this profile.", in: view)
            return
        }
        navigationController?.pushViewController(
            CreatorProfileViewController(
                creatorIdentifier: identifier,
                currentUserIdentifier: currentUserIdentifier
            ),
            animated: true
        )
    }

    @objc private func goBack() {
        navigationController?.popViewController(animated: true)
    }
}
