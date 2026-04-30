import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
@Observable
final class ThirdPartyPaymentService {
    static let shared = ThirdPartyPaymentService()

    private(set) var isProcessing = false
    private(set) var pendingOrderId: String?

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "thirdparty-pay")

    private init() {}

    // MARK: - WeChat Pay

    var isWeChatPayAvailable: Bool {
        #if os(iOS)
        guard let url = URL(string: "weixin://") else { return false }
        return UIApplication.shared.canOpenURL(url)
        #else
        return false
        #endif
    }

    func requestWeChatPay(
        productId: String,
        amount: Decimal,
        currency: String = "CNY"
    ) async throws -> PaymentResult {
        self.isProcessing = true
        defer { isProcessing = false }

        let order = try await createServerOrder(
            provider: "wechat",
            productId: productId,
            amount: amount,
            currency: currency
        )

        self.pendingOrderId = order.orderId

        #if os(iOS)
        if let payURL = URL(string: order.paymentScheme) {
            let opened = await UIApplication.shared.open(payURL)
            if !opened {
                self.logger.failed("Failed to open WeChat", error: StoreError.purchaseFailed)
                return .failed(StoreError.purchaseFailed)
            }
            self.logger.info("WeChat Pay initiated for order: \(order.orderId)")
            return .success(transactionId: order.orderId)
        }
        #endif

        return .failed(StoreError.purchaseFailed)
    }

    // MARK: - Alipay

    var isAlipayAvailable: Bool {
        #if os(iOS)
        guard let url = URL(string: "alipay://") else { return false }
        return UIApplication.shared.canOpenURL(url)
        #else
        return true
        #endif
    }

    func requestAlipay(
        productId: String,
        amount: Decimal,
        currency: String = "CNY"
    ) async throws -> PaymentResult {
        self.isProcessing = true
        defer { isProcessing = false }

        let order = try await createServerOrder(
            provider: "alipay",
            productId: productId,
            amount: amount,
            currency: currency
        )

        self.pendingOrderId = order.orderId

        guard let payURL = URL(string: order.paymentScheme) else {
            return .failed(StoreError.purchaseFailed)
        }

        #if os(iOS)
        let opened = await UIApplication.shared.open(payURL)
        if !opened {
            if let webURL = URL(string: order.webPaymentURL ?? "") {
                await UIApplication.shared.open(webURL)
            }
        }
        #elseif os(macOS)
        if let webURL = URL(string: order.webPaymentURL ?? "") {
            NSWorkspace.shared.open(webURL)
        }
        #endif

        self.logger.info("Alipay initiated for order: \(order.orderId)")
        return .success(transactionId: order.orderId)
    }

    // MARK: - PayPal

    func requestPayPal(
        productId: String,
        amount: Decimal,
        currency: String = "USD"
    ) async throws -> PaymentResult {
        self.isProcessing = true
        defer { isProcessing = false }

        let order = try await createServerOrder(
            provider: "paypal",
            productId: productId,
            amount: amount,
            currency: currency
        )

        self.pendingOrderId = order.orderId

        guard let approvalURL = URL(string: order.webPaymentURL ?? order.paymentScheme) else {
            return .failed(StoreError.purchaseFailed)
        }

        #if os(iOS)
        await UIApplication.shared.open(approvalURL)
        #elseif os(macOS)
        NSWorkspace.shared.open(approvalURL)
        #endif

        self.logger.info("PayPal initiated for order: \(order.orderId)")
        return .success(transactionId: order.orderId)
    }

    // MARK: - Verify Callback

    func handlePaymentCallback(url: URL) async -> Bool {
        guard let orderId = pendingOrderId else { return false }

        let verified = await verifyOrder(orderId: orderId)
        if verified {
            self.logger.completed("Third-party payment verified: \(orderId)")
            AnalyticsManager.shared.track(.purchaseCompleted(productId: orderId))
            await MainActor.run {
                let source = self.resolveEntitlementSource(from: url)
                EntitlementManager.shared.onThirdPartyPaymentVerified(source: source, transactionId: orderId)
            }
        }
        self.pendingOrderId = nil
        return verified
    }

    private func resolveEntitlementSource(from url: URL) -> EntitlementSource {
        let host = url.host ?? ""
        if host.contains("wechat") || host.contains("wx") { return .wechatPay }
        if host.contains("alipay") { return .alipay }
        if host.contains("paypal") { return .paypal }
        return .stripe
    }

    // MARK: - Server Communication

    private func createServerOrder(
        provider: String,
        productId: String,
        amount: Decimal,
        currency: String
    ) async throws -> ServerOrderResponse {
        let url = PaymentConfig.shared.serverBaseURL
            .appendingPathComponent("/api/payments/\(provider)/create-order")

        let body = OrderRequest(
            productId: productId,
            amount: "\(amount)",
            currency: currency,
            callbackURL: "scrollcap://payment/\(provider)/callback"
        )

        return try await APIClient.shared.post(
            ServerOrderResponse.self, url: url, body: body
        )
    }

    private func verifyOrder(orderId: String) async -> Bool {
        let url = PaymentConfig.shared.serverBaseURL
            .appendingPathComponent("/api/payments/verify")

        do {
            let result = try await APIClient.shared.post(
                PaymentServerResponse.self,
                url: url,
                body: ["orderId": orderId]
            )
            return result.status == "paid"
        } catch {
            self.logger.failed("Order verification failed", error: error)
            return false
        }
    }
}

// MARK: - Models

private struct OrderRequest: Codable {
    let productId: String
    let amount: String
    let currency: String
    let callbackURL: String
}

struct ServerOrderResponse: Codable {
    let orderId: String
    let paymentScheme: String
    let webPaymentURL: String?
}
