import Foundation
import Security

extension Notification.Name {
    static let kivroCoinBalanceDidChange = Notification.Name(
        KivroConstantMask.join("kivro.coin.", "balance.did.", "change")
    )
}

final class KivroCoinWallet {
    static let shared = KivroCoinWallet()

    enum PurchaseCreditResult {
        case credited
        case alreadyCredited
        case failed
    }

    private struct WalletRecord: Codable {
        var balance: Int
        var creditedTransactionIdentifiers: Set<String>
    }

    private let service = KivroConstantMask.join("app.myfy.", "kivro.", "wallet")
    private let initialBalance = 0
    private let defaults = UserDefaults.standard

    private init() {}

    func balance(for userIdentifier: String) -> Int {
        if let record = readKeychainRecord(for: userIdentifier) {
            _ = writeKeychainRecord(record, for: userIdentifier)
            mirror(record.balance, for: userIdentifier)
            return record.balance
        }

        let record = WalletRecord(balance: initialBalance, creditedTransactionIdentifiers: [])
        _ = writeKeychainRecord(record, for: userIdentifier)
        mirror(initialBalance, for: userIdentifier)
        return initialBalance
    }

    @discardableResult
    func spend(_ amount: Int, for userIdentifier: String) -> Bool {
        guard amount > 0 else { return true }
        var record = walletRecord(for: userIdentifier)
        guard record.balance >= amount else { return false }
        record.balance -= amount
        return save(record, for: userIdentifier)
    }

    @discardableResult
    func credit(_ amount: Int, for userIdentifier: String) -> Bool {
        guard amount > 0 else { return false }
        var record = walletRecord(for: userIdentifier)
        record.balance += amount
        return save(record, for: userIdentifier)
    }

    func creditPurchase(
        _ amount: Int,
        for userIdentifier: String,
        transactionIdentifier: String
    ) -> PurchaseCreditResult {
        guard amount > 0 else { return .failed }
        var record = walletRecord(for: userIdentifier)
        guard !transactionIdentifier.isEmpty,
              !record.creditedTransactionIdentifiers.contains(transactionIdentifier) else {
            return .alreadyCredited
        }
        record.balance += amount
        record.creditedTransactionIdentifiers.insert(transactionIdentifier)
        return save(record, for: userIdentifier) ? .credited : .failed
    }

    @discardableResult
    func deleteWallet(for userIdentifier: String) -> Bool {
        let status = SecItemDelete(baseQuery(for: userIdentifier) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { return false }
        defaults.removeObject(forKey: mirrorKey(for: userIdentifier))
        return true
    }

    private func walletRecord(for userIdentifier: String) -> WalletRecord {
        if let record = readKeychainRecord(for: userIdentifier) {
            _ = writeKeychainRecord(record, for: userIdentifier)
            return record
        }
        return WalletRecord(balance: initialBalance, creditedTransactionIdentifiers: [])
    }

    private func save(_ record: WalletRecord, for userIdentifier: String) -> Bool {
        guard writeKeychainRecord(record, for: userIdentifier) else { return false }
        mirror(record.balance, for: userIdentifier)
        NotificationCenter.default.post(
            name: .kivroCoinBalanceDidChange,
            object: nil,
            userInfo: ["userIdentifier": userIdentifier, "balance": record.balance]
        )
        return true
    }

    private func readKeychainRecord(for userIdentifier: String) -> WalletRecord? {
        var query = baseQuery(for: userIdentifier)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        if let record = try? JSONDecoder().decode(WalletRecord.self, from: data) {
            return record
        }
        guard String(data: data, encoding: .utf8).flatMap(Int.init) != nil else { return nil }
        return WalletRecord(balance: initialBalance, creditedTransactionIdentifiers: [])
    }

    private func writeKeychainRecord(_ record: WalletRecord, for userIdentifier: String) -> Bool {
        guard let data = try? JSONEncoder().encode(record) else { return false }
        let query = baseQuery(for: userIdentifier)
        let attributes = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess { return true }
        guard updateStatus == errSecItemNotFound else { return false }

        var newItem = query
        newItem[kSecValueData as String] = data
        newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(newItem as CFDictionary, nil) == errSecSuccess
    }

    private func baseQuery(for userIdentifier: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: KivroConstantMask.join("co", "ins.", userIdentifier)
        ]
    }

    private func mirror(_ balance: Int, for userIdentifier: String) {
        defaults.set(balance, forKey: mirrorKey(for: userIdentifier))
    }

    private func mirrorKey(for userIdentifier: String) -> String {
        KivroConstantMask.join("kivro.wallet.", "balance.", userIdentifier)
    }
}
