import Foundation

final class KivroProductState {
    static let shared = KivroProductState()

    private let defaults = UserDefaults.standard

    private init() {}

    func isPersonaCardUnlocked(for userIdentifier: String) -> Bool {
        defaults.bool(forKey: personaCardKey(for: userIdentifier))
    }

    func unlockPersonaCard(for userIdentifier: String) {
        defaults.set(true, forKey: personaCardKey(for: userIdentifier))
    }

    func lockPersonaCard(for userIdentifier: String) {
        defaults.set(false, forKey: personaCardKey(for: userIdentifier))
    }

    func grantRadarProfileAccess(for userIdentifier: String) {
        defaults.set(true, forKey: radarProfileAccessKey(for: userIdentifier))
    }

    func consumeRadarProfileAccess(for userIdentifier: String) -> Bool {
        let key = radarProfileAccessKey(for: userIdentifier)
        guard defaults.bool(forKey: key) else { return false }
        defaults.set(false, forKey: key)
        return true
    }

    func clear(for userIdentifier: String) {
        defaults.removeObject(forKey: personaCardKey(for: userIdentifier))
        defaults.removeObject(forKey: radarProfileAccessKey(for: userIdentifier))
    }

    private func personaCardKey(for userIdentifier: String) -> String {
        KivroConstantMask.join("kivro.persona.", "card.unlocked.", userIdentifier)
    }

    private func radarProfileAccessKey(for userIdentifier: String) -> String {
        KivroConstantMask.join("kivro.radar.", "profile.access.", userIdentifier)
    }
}
