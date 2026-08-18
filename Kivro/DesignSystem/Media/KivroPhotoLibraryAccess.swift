import Photos
import UIKit

enum KivroPhotoLibraryAccess {
    static func request(from viewController: UIViewController, completion: @escaping () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        handle(status, from: viewController, completion: completion)
    }

    private static func handle(
        _ status: PHAuthorizationStatus,
        from viewController: UIViewController,
        completion: @escaping () -> Void
    ) {
        switch status {
        case .authorized, .limited:
            completion()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { updatedStatus in
                DispatchQueue.main.async {
                    handle(updatedStatus, from: viewController, completion: completion)
                }
            }
        case .denied, .restricted:
            KivroToastPresenter.show(
                message: "Photo access is disabled in Settings.",
                in: viewController.view
            )
        @unknown default:
            KivroToastPresenter.show(
                message: "Photo access is unavailable.",
                in: viewController.view
            )
        }
    }
}
