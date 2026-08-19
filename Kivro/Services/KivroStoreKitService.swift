import CryptoKit
import Foundation
import StoreKit

@MainActor
final class KivroStoreKitService {
    static let shared = KivroStoreKitService()

    enum PurchaseOutcome {
        case credited
        case alreadyCredited
        case pending
        case cancelled
        case unavailable
        case unverified
        case mismatched
        case creditFailed
        case failed
    }

    private enum DeliveryOutcome {
        case credited
        case alreadyCredited
        case mismatched
        case creditFailed
    }

    private let defaults = UserDefaults.standard
    private var productsByIdentifier: [String: Product] = [:]
    private var transactionUpdatesTask: Task<Void, Never>?
    private var unfinishedTransactionsTask: Task<Void, Never>?

    private init() {}

    func start() {
        guard transactionUpdatesTask == nil else { return }
        transactionUpdatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.processBackgroundTransaction(result)
            }
        }
        unfinishedTransactionsTask = Task { [weak self] in
            for await result in Transaction.unfinished {
                guard !Task.isCancelled else { return }
                await self?.processBackgroundTransaction(result)
            }
        }
    }

    func products(for packages: [CoinPackage]) async throws -> [String: Product] {
        let identifiers = packages.map(\.productIdentifier)
        let fetchedProducts = try await Product.products(for: identifiers)
        fetchedProducts.forEach { productsByIdentifier[$0.id] = $0 }
        return Dictionary(uniqueKeysWithValues: fetchedProducts.map { ($0.id, $0) })
    }

    func purchase(package: CoinPackage, userIdentifier: String) async -> PurchaseOutcome {
        let product: Product
        if let cachedProduct = productsByIdentifier[package.productIdentifier] {
            product = cachedProduct
        } else {
            do {
                guard let fetchedProduct = try await Product.products(for: [package.productIdentifier])
                    .first(where: { $0.id == package.productIdentifier }) else {
                    return .unavailable
                }
                productsByIdentifier[fetchedProduct.id] = fetchedProduct
                product = fetchedProduct
            } catch {
                return .unavailable
            }
        }

        let accountToken = Self.accountToken(for: userIdentifier)
        remember(userIdentifier: userIdentifier, for: accountToken)

        do {
            let result = try await product.purchase(options: [.appAccountToken(accountToken)])
            switch result {
            case .success(let verificationResult):
                guard case .verified(let transaction) = verificationResult else {
                    return .unverified
                }
                let outcome = await deliver(
                    transaction,
                    package: package,
                    userIdentifier: userIdentifier,
                    expectedAccountToken: accountToken
                )
                switch outcome {
                case .credited:
                    return .credited
                case .alreadyCredited:
                    return .alreadyCredited
                case .mismatched:
                    return .mismatched
                case .creditFailed:
                    return .creditFailed
                }
            case .pending:
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch let purchaseError as Product.PurchaseError {
            switch purchaseError {
            case .productUnavailable, .purchaseNotAllowed:
                return .unavailable
            default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    func clearAccountMapping(for userIdentifier: String) {
        let accountToken = Self.accountToken(for: userIdentifier)
        defaults.removeObject(forKey: accountTokenUserKey(accountToken))
    }

    private func processBackgroundTransaction(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result,
              let package = CoinPackage.rechargePackages.first(where: {
                  $0.productIdentifier == transaction.productID
              }) else { return }
        let accountToken = transaction.appAccountToken
        let resolvedUserIdentifier = accountToken.flatMap { self.userIdentifier(for: $0) }
            ?? legacyUserIdentifier(for: transaction.productID)
        guard let resolvedUserIdentifier else { return }
        _ = await deliver(
            transaction,
            package: package,
            userIdentifier: resolvedUserIdentifier,
            expectedAccountToken: accountToken
        )
    }

    private func deliver(
        _ transaction: Transaction,
        package: CoinPackage,
        userIdentifier: String,
        expectedAccountToken: UUID?
    ) async -> DeliveryOutcome {
        guard transaction.productID == package.productIdentifier,
              transaction.appAccountToken == expectedAccountToken,
              KivroSeedDatabase.shared.user(identifier: userIdentifier) != nil else {
            return .mismatched
        }

        let result = KivroCoinWallet.shared.creditPurchase(
            package.coinAmount,
            for: userIdentifier,
            transactionIdentifier: String(transaction.id)
        )
        switch result {
        case .credited:
            await transaction.finish()
            clearLegacyUserIdentifier(for: package.productIdentifier)
            return .credited
        case .alreadyCredited:
            await transaction.finish()
            clearLegacyUserIdentifier(for: package.productIdentifier)
            return .alreadyCredited
        case .failed:
            return .creditFailed
        }
    }

    private func remember(userIdentifier: String, for accountToken: UUID) {
        defaults.set(userIdentifier, forKey: accountTokenUserKey(accountToken))
    }

    private func userIdentifier(for accountToken: UUID) -> String? {
        if let storedIdentifier = defaults.string(forKey: accountTokenUserKey(accountToken)) {
            return storedIdentifier
        }
        guard let currentUser = KivroSessionState.shared.currentUser,
              !currentUser.isGuest,
              Self.accountToken(for: currentUser.identifier) == accountToken else { return nil }
        remember(userIdentifier: currentUser.identifier, for: accountToken)
        return currentUser.identifier
    }

    private func accountTokenUserKey(_ accountToken: UUID) -> String {
        KivroConstantMask.join("kivro.store.account-token.", accountToken.uuidString.lowercased())
    }

    private func legacyUserIdentifier(for productIdentifier: String) -> String? {
        defaults.string(forKey: legacyPurchaseUserKey(productIdentifier))
    }

    private func clearLegacyUserIdentifier(for productIdentifier: String) {
        defaults.removeObject(forKey: legacyPurchaseUserKey(productIdentifier))
    }

    private func legacyPurchaseUserKey(_ productIdentifier: String) -> String {
        KivroConstantMask.join("kivro.purchase.", "user.", productIdentifier)
    }

    private static func accountToken(for userIdentifier: String) -> UUID {
        let digest = SHA256.hash(data: Data(userIdentifier.utf8))
        var bytes = Array(digest.prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        let value: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: value)
    }
}
