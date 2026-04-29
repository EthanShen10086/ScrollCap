import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
@Observable
final class StripePaymentService {
    static let shared = StripePaymentService()

    private(set) var isProcessing = false

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "stripe")

    private init() {}

    func createCheckoutSession(
        productId: String,
        priceInCents: Int,
        currency: String = "usd"
    ) async throws -> PaymentResult {
        isProcessing = true
        defer { isProcessing = false }

        let serverURL = PaymentConfig.shared.serverBaseURL
            .appendingPathComponent("/api/payments/stripe/create-session")

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = StripeSessionRequest(
            productId: productId,
            priceInCents: priceInCents,
            currency: currency,
            successURL: "scrollcap://payment/success",
            cancelURL: "scrollcap://payment/cancel"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200 ... 299 ~= httpResponse.statusCode
        else {
            throw StoreError.networkError("Stripe session creation failed")
        }

        let session = try JSONDecoder().decode(StripeSessionResponse.self, from: data)

        openCheckoutURL(session.checkoutURL)

        return .success(transactionId: session.sessionId)
    }

    func verifyPayment(sessionId: String) async throws -> Bool {
        let serverURL = PaymentConfig.shared.serverBaseURL
            .appendingPathComponent("/api/payments/stripe/verify")

        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["sessionId": sessionId])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200 ... 299 ~= httpResponse.statusCode
        else {
            return false
        }

        let result = try JSONDecoder().decode(PaymentServerResponse.self, from: data)
        if result.status == "paid" {
            logger.completed("Stripe payment verified: \(sessionId)")
            AnalyticsManager.shared.track(.purchaseCompleted(productId: "stripe_\(sessionId)"))
            return true
        }
        return false
    }

    private func openCheckoutURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(iOS)
        UIApplication.shared.open(url)
        #elseif os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}

// MARK: - Stripe Models

private struct StripeSessionRequest: Codable {
    let productId: String
    let priceInCents: Int
    let currency: String
    let successURL: String
    let cancelURL: String
}

private struct StripeSessionResponse: Codable {
    let sessionId: String
    let checkoutURL: String
}
