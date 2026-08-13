import UIKit

extension Notification.Name {
    static let kivroProfileAvatarDidChange = Notification.Name(
        KivroConstantMask.join("kivro.profile.", "avatar.did.", "change")
    )
    static let kivroProfileDidChange = Notification.Name(
        KivroConstantMask.join("kivro.", "profile.did.", "change")
    )
}

final class KivroProfileState {
    static let shared = KivroProfileState()

    private let defaults = UserDefaults.standard

    private init() {}

    func avatar(for userIdentifier: String) -> UIImage? {
        guard let data = defaults.data(forKey: avatarKey(for: userIdentifier)) else { return nil }
        return UIImage(data: data)
    }

    func name(for userIdentifier: String) -> String? {
        defaults.string(forKey: nameKey(for: userIdentifier))
    }

    func resolvedName(for userIdentifier: String) -> String {
        if let name = name(for: userIdentifier), !name.isEmpty { return name }
        if let user = KivroSeedDatabase.shared.user(identifier: userIdentifier) {
            return user.username
        }
        if KivroSessionState.shared.currentUserIdentifier == userIdentifier,
           let sessionUser = KivroSessionState.shared.currentUser {
            return sessionUser.displayName
        }
        return "User"
    }

    func resolvedAvatar(for userIdentifier: String) -> UIImage? {
        if let avatar = avatar(for: userIdentifier) { return avatar }
        guard let assetName = KivroSeedDatabase.shared.user(identifier: userIdentifier)?.avatarAssetName else {
            return nil
        }
        return UIImage(named: assetName)
    }

    func resolvedAvatarAssetName(for userIdentifier: String) -> String {
        KivroSeedDatabase.shared.user(identifier: userIdentifier)?.avatarAssetName
            ?? "kivro_profile_header_avatar"
    }

    @discardableResult
    func saveProfile(name: String, avatar: UIImage?, for userIdentifier: String) -> Bool {
        var avatarData: Data?
        if let avatar {
            let targetSize = CGSize(width: 640, height: 640)
            let storedImage = avatar.preparingThumbnail(of: targetSize) ?? avatar
            guard let data = storedImage.jpegData(compressionQuality: 0.82) else { return false }
            avatarData = data
        }

        defaults.set(name, forKey: nameKey(for: userIdentifier))
        if let avatarData {
            defaults.set(avatarData, forKey: avatarKey(for: userIdentifier))
        }
        NotificationCenter.default.post(
            name: .kivroProfileDidChange,
            object: nil,
            userInfo: ["userIdentifier": userIdentifier]
        )
        return true
    }

    @discardableResult
    func saveAvatar(_ image: UIImage, for userIdentifier: String) -> Bool {
        let targetSize = CGSize(width: 640, height: 640)
        let storedImage = image.preparingThumbnail(of: targetSize) ?? image
        guard let data = storedImage.jpegData(compressionQuality: 0.82) else { return false }
        defaults.set(data, forKey: avatarKey(for: userIdentifier))
        NotificationCenter.default.post(
            name: .kivroProfileAvatarDidChange,
            object: nil,
            userInfo: ["userIdentifier": userIdentifier]
        )
        return true
    }

    func clear(for userIdentifier: String) {
        defaults.removeObject(forKey: avatarKey(for: userIdentifier))
        defaults.removeObject(forKey: nameKey(for: userIdentifier))
    }

    private func avatarKey(for userIdentifier: String) -> String {
        KivroConstantMask.join("kivro.profile.", "avatar.", userIdentifier)
    }

    private func nameKey(for userIdentifier: String) -> String {
        KivroConstantMask.join("kivro.", "profile.name.", userIdentifier)
    }
}
