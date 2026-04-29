import Foundation
import OSLog
import StoreKit

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var subscriptionStatus: SubscriptionInfo?

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "store")
    private var updateListenerTask: Task<Void, Error>?

    static let productIDs: [String] = [
        "scrollcap_pro_monthly",
        "scrollcap_pro_yearly",
        "scrollcap_pro_lifetime",
    ]

    static let subscriptionGroupID = "A1B2C3D4-0001"

    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await refreshPurchaseState() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            logger.info("Loaded \(products.count) products")
        } catch {
            logger.failed("Failed to load products", error: error)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case let .success(verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            await refreshSubscriptionStatus()
            logger.completed("Purchased \(product.id)")
            AnalyticsManager.shared.track(.purchaseCompleted(productId: product.id))
            return true

        case .userCancelled:
            logger.info("User cancelled purchase")
            return false

        case .pending:
            logger.info("Purchase pending")
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        var restored = 0
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
                restored += 1
            }
        }
        await refreshSubscriptionStatus()
        logger.info("Restored \(restored) purchases")
    }

    // MARK: - Subscription Management

    func refreshPurchaseState() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
        await refreshSubscriptionStatus()
    }

    func refreshSubscriptionStatus() async {
        guard let statuses = try? await Product.SubscriptionInfo.status(
            for: Self.subscriptionGroupID
        ) else { return }

        for status in statuses {
            guard let transaction = try? checkVerified(status.transaction) else { continue }

            let renewalState = status.state
            subscriptionStatus = SubscriptionInfo(
                productID: transaction.productID,
                expirationDate: transaction.expirationDate,
                isAutoRenewing: renewalState == .subscribed,
                state: renewalState
            )

            if renewalState == .subscribed || renewalState == .inGracePeriod {
                purchasedProductIDs.insert(transaction.productID)
            } else if renewalState == .expired || renewalState == .revoked {
                purchasedProductIDs.remove(transaction.productID)
            }
        }
    }

    @available(iOS 17.0, macOS 14.0, *)
    func openManageSubscriptions() async {
        #if os(iOS)
        guard let windowScene = await UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first
        else { return }
        try? await AppStore.showManageSubscriptions(in: windowScene)
        #else
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                let transaction: Transaction
                switch result {
                case .unverified:
                    continue
                case let .verified(verified):
                    transaction = verified
                }
                await MainActor.run {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
                await transaction.finish()
                await self.refreshSubscriptionStatus()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case let .verified(safe):
            return safe
        }
    }
}

// MARK: - Models

struct SubscriptionInfo {
    let productID: String
    let expirationDate: Date?
    let isAutoRenewing: Bool
    let state: Product.SubscriptionInfo.RenewalState
}

enum StoreError: Error, LocalizedError {
    case verificationFailed
    case purchaseFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "Transaction verification failed."
        case .purchaseFailed: "Purchase could not be completed."
        case let .networkError(msg): "Network error: \(msg)"
        }
    }
}
