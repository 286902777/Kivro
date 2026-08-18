import AVFoundation
import UIKit

enum KivroCaptureAuthorization {
    enum Mode {
        case photo
        case video
    }

    static func request(
        mode: Mode,
        from viewController: UIViewController,
        completion: @escaping () -> Void
    ) {
        requestDeviceAccess(
            for: .video,
            deniedMessage: "Camera access is disabled in Settings.",
            from: viewController
        ) { cameraGranted in
            guard cameraGranted else { return }
            guard mode == .video else {
                completion()
                return
            }
            requestDeviceAccess(
                for: .audio,
                deniedMessage: "Microphone access is disabled in Settings.",
                from: viewController,
                completion: { microphoneGranted in
                    guard microphoneGranted else { return }
                    completion()
                }
            )
        }
    }

    private static func requestDeviceAccess(
        for mediaType: AVMediaType,
        deniedMessage: String,
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        KivroToastPresenter.show(message: deniedMessage, in: viewController.view)
                    }
                    completion(granted)
                }
            }
        case .denied, .restricted:
            KivroToastPresenter.show(message: deniedMessage, in: viewController.view)
            completion(false)
        @unknown default:
            KivroToastPresenter.show(message: "Capture access is unavailable.", in: viewController.view)
            completion(false)
        }
    }
}
