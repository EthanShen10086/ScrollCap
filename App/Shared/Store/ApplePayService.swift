import Foundation
import OSLog
import PassKit

@MainActor
final class ApplePayService: NSObject {
    static let shared = ApplePayService()

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "applepay")
    private var paymentCompletion: ((PaymentResult) -> Void)?

    static var isAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments(
            usingNetworks: supportedNetworks,
            capabilities: .threeDSecure
        )
    }

    private static let supportedNetworks: [PKPaymentNetwork] = [
        .visa, .masterCard, .amex, .chinaUnionPay, .JCB, .discover,
    ]

    func requestPayment(
        amount: Decimal,
        currency: String = "CNY",
        productDescription: String
    ) async -> PaymentResult {
        let item = PKPaymentSummaryItem(
            label: productDescription,
            amount: NSDecimalNumber(decimal: amount)
        )
        let total = PKPaymentSummaryItem(
            label: "ScrollCap",
            amount: NSDecimalNumber(decimal: amount)
        )

        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.ethanshen.scrollcap"
        request.supportedNetworks = Self.supportedNetworks
        request.merchantCapabilities = .threeDSecure
        request.countryCode = currency == "CNY" ? "CN" : "US"
        request.currencyCode = currency
        request.paymentSummaryItems = [item, total]

        return await withCheckedContinuation { continuation in
            self.paymentCompletion = { result in
                continuation.resume(returning: result)
            }

            let controller = PKPaymentAuthorizationController(paymentRequest: request)
            controller.delegate = self
            controller.present { presented in
                if !presented {
                    self.logger.failed("Failed to present Apple Pay", error: StoreError.purchaseFailed)
                    self.paymentCompletion?(.failed(StoreError.purchaseFailed))
                    self.paymentCompletion = nil
                }
            }
        }
    }
}

extension ApplePayService: @preconcurrency PKPaymentAuthorizationControllerDelegate {
    nonisolated func paymentAuthorizationControllerDidFinish(
        _ controller: PKPaymentAuthorizationController
    ) {
        controller.dismiss {
            Task { @MainActor in
                if self.paymentCompletion != nil {
                    self.paymentCompletion?(.cancelled)
                    self.paymentCompletion = nil
                }
            }
        }
    }

    nonisolated func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        let tokenData = payment.token.paymentData
        nonisolated(unsafe) let completion = completion

        Task { @MainActor in
            do {
                let transactionID = try await self.processPaymentOnServer(tokenData: tokenData)
                self.logger.completed("Apple Pay transaction: \(transactionID)")
                AnalyticsManager.shared.track(.purchaseCompleted(productId: "applepay"))
                self.paymentCompletion?(.success(transactionId: transactionID))
                self.paymentCompletion = nil
                completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            } catch {
                self.logger.failed("Apple Pay server processing failed", error: error)
                self.paymentCompletion?(.failed(error))
                self.paymentCompletion = nil
                completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            }
        }
    }

    #if os(macOS)
    nonisolated func presentationWindow(for controller: PKPaymentAuthorizationController) -> NSWindow? {
        nil
    }
    #endif

    @MainActor
    private func processPaymentOnServer(tokenData: Data) async throws -> String {
        let url = PaymentConfig.shared.serverBaseURL
            .appendingPathComponent("/api/payments/apple-pay/process")

        let body = ApplePayTokenRequest(
            paymentToken: tokenData.base64EncodedString(),
            bundleId: Bundle.main.bundleIdentifier ?? ""
        )

        let result = try await APIClient.shared.post(
            PaymentServerResponse.self, url: url, body: body
        )
        return result.transactionId
    }
}

private struct ApplePayTokenRequest: Codable {
    let paymentToken: String
    let bundleId: String
}
