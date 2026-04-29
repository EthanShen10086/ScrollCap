import Foundation
import StoreKit
import OSLog

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "store")
    private var updateListenerTask: Task<Void, Error>?

    static let productIDs: [String] = [
        "scrollcap_pro_monthly",
        "scrollcap_pro_yearly",
        "scrollcap_pro_lifetime"
    ]

    var isPro: Bool {
        !purchasedProductIDs.isEmpty
    }

    private init() {
        updateListenerTask = listenForTransactions()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.productIDs)
                .sorted { $0.price < $1.price }
            logger.info("Loaded \(self.products.count) products")
        } catch {
            logger.failed("Failed to load products", error: error)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            purchasedProductIDs.insert(transaction.productID)
            await transaction.finish()
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
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchasedProductIDs.insert(transaction.productID)
            }
        }
        logger.info("Restored \(self.purchasedProductIDs.count) purchases")
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                let transaction: Transaction
                switch result {
                case .unverified:
                    continue
                case .verified(let t):
                    transaction = t
                }
                await MainActor.run {
                    self.purchasedProductIDs.insert(transaction.productID)
                }
                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error, LocalizedError {
    case verificationFailed
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed: "Transaction verification failed."
        case .purchaseFailed: "Purchase could not be completed."
        }
    }
}
