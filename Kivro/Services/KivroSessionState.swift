import Foundation

struct KivroSessionUser: Codable, Equatable {
    let identifier: String
    let email: String?
    let displayName: String
    let isGuest: Bool
    let createdAt: Date
}

struct KivroPendingRegistration {
    let identifier: String
    let email: String
    let password: String
}

final class KivroSessionState {
    static let shared = KivroSessionState()

    private enum PersistenceKey {
        static let currentUser = KivroConstantMask.join("kiv", "ro.session.", "current-user")
        static let pendingRegistrationEmail = KivroConstantMask.join(
            "kivro.", "session.pending-", "registration-email"
        )
        static let pendingRegistrationPassword = KivroConstantMask.join(
            "kivro.session.", "pending-registration-", "password"
        )
        static let pendingRegistrationIdentifier = KivroConstantMask.join(
            "kivro.session.pending-", "registration-", "identifier"
        )
    }

    private let defaults: UserDefaults
    private(set) var currentUser: KivroSessionUser?

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        restorePersistedSession()
    }

    var isAuthenticated: Bool {
        currentUser != nil
    }

    var isGuest: Bool {
        currentUser?.isGuest == true
    }

    var currentUserIdentifier: String {
        currentUser?.identifier ?? "anonymous"
    }

    @discardableResult
    func continueAsGuest() -> KivroSessionUser {
        if let currentUser, currentUser.isGuest {
            return currentUser
        }
        let user = KivroSessionUser(
            identifier: "guest_\(UUID().uuidString.lowercased())",
            email: nil,
            displayName: "Guest",
            isGuest: true,
            createdAt: Date()
        )
        establishSession(for: user)
        return user
    }

    func signIn(email: String, displayName: String? = nil, identifier: String? = nil) {
        let normalizedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let resolvedIdentifier = identifier
            ?? "account_\(normalizedEmail.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString)"
        establishSession(
            for: KivroSessionUser(
                identifier: resolvedIdentifier,
                email: normalizedEmail,
                displayName: displayName ?? "Evelyn",
                isGuest: false,
                createdAt: Date()
            )
        )
    }

    var pendingRegistration: KivroPendingRegistration? {
        guard let identifier = defaults.string(forKey: PersistenceKey.pendingRegistrationIdentifier),
              let email = defaults.string(forKey: PersistenceKey.pendingRegistrationEmail),
              let password = defaults.string(forKey: PersistenceKey.pendingRegistrationPassword) else {
            return nil
        }
        return KivroPendingRegistration(
            identifier: identifier,
            email: email,
            password: password
        )
    }

    func beginRegistration(email: String, password: String) {
        defaults.set(
            email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            forKey: PersistenceKey.pendingRegistrationEmail
        )
        defaults.set(password, forKey: PersistenceKey.pendingRegistrationPassword)
        defaults.set(
            "account_\(UUID().uuidString.lowercased())",
            forKey: PersistenceKey.pendingRegistrationIdentifier
        )
    }

    func clearPendingRegistration() {
        defaults.removeObject(forKey: PersistenceKey.pendingRegistrationEmail)
        defaults.removeObject(forKey: PersistenceKey.pendingRegistrationPassword)
        defaults.removeObject(forKey: PersistenceKey.pendingRegistrationIdentifier)
    }

    func relinquishSession() {
        defaults.removeObject(forKey: PersistenceKey.currentUser)
        clearPendingRegistration()
        currentUser = nil
    }

    private func restorePersistedSession() {
        guard let data = defaults.data(forKey: PersistenceKey.currentUser),
              let user = try? JSONDecoder().decode(KivroSessionUser.self, from: data) else {
            defaults.removeObject(forKey: PersistenceKey.currentUser)
            currentUser = nil
            return
        }
        currentUser = user
    }

    private func establishSession(for user: KivroSessionUser) {
        guard let data = try? JSONEncoder().encode(user) else { return }
        defaults.set(data, forKey: PersistenceKey.currentUser)
        currentUser = user
    }
}
