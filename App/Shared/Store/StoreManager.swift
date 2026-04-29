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
        !self.purchasedProductIDs.isEmpty
    }

    private init() {
        self.updateListenerTask = self.listenForTransactions()
        Task { await self.refreshPurchaseState() }
    }

    // MARK: - Load Products

    func loadProducts() async {
        self.isLoading = true
        defer { isLoading = false }

        do {
            self.products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            self.logger.info("Loaded \(self.products.count) products")
        } catch {
            self.logger.failed("Failed to load products", error: error)
            AnalyticsManager.shared.track(.error(domain: "store", code: "load_products_failed"))
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case let .success(verification):
            let transaction = try checkVerified(verification)
            self.purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
            await self.refreshSubscriptionStatus()
            self.logger.completed("Purchased \(product.id)")
            AnalyticsManager.shared.track(.purchaseCompleted(productId: product.id))
            return true

        case .userCancelled:
            self.logger.info("User cancelled purchase")
            AnalyticsManager.shared.track(.purchaseCancelled(productId: product.id))
            return false

        case .pending:
            self.logger.info("Purchase pending")
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
                self.purchasedProductIDs.insert(transaction.productID)
                restored += 1
            }
        }
        await self.refreshSubscriptionStatus()
        self.logger.info("Restored \(restored) purchases")
        AnalyticsManager.shared.track(.restoreCompleted(count: restored))
    }

    // MARK: - Subscription Management

    func refreshPurchaseState() async {
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                self.purchasedProductIDs.insert(transaction.productID)
            }
        }
        await self.refreshSubscriptionStatus()
    }

    func refreshSubscriptionStatus() async {
        guard let statuses = try? await Product.SubscriptionInfo.status(
            for: Self.subscriptionGroupID
        ) else { return }

        for status in statuses {
            guard let transaction = try? checkVerified(status.transaction) else { continue }

            let renewalState = status.state
            self.subscriptionStatus = SubscriptionInfo(
                productID: transaction.productID,
                expirationDate: transaction.expirationDate,
                isAutoRenewing: renewalState == .subscribed,
                state: renewalState
            )

            if renewalState == .subscribed || renewalState == .inGracePeriod {
                self.purchasedProductIDs.insert(transaction.productID)
            } else if renewalState == .expired || renewalState == .revoked {
                self.purchasedProductIDs.remove(transaction.productID)
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
