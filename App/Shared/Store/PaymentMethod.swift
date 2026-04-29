import SwiftUI

enum PaymentMethod: String, CaseIterable {
    case applePurchase
    case applePay
    case stripe
    case wechatPay
    case alipay
    case paypal

    var displayName: LocalizedStringKey {
        switch self {
        case .applePurchase: "payment.appStore"
        case .applePay: "payment.applePay"
        case .stripe: "payment.stripe"
        case .wechatPay: "payment.wechatPay"
        case .alipay: "payment.alipay"
        case .paypal: "payment.payPal"
        }
    }

    var icon: String {
        switch self {
        case .applePurchase: "apple.logo"
        case .applePay: "apple.logo"
        case .stripe: "creditcard.fill"
        case .wechatPay: "message.fill"
        case .alipay: "dollarsign.circle.fill"
        case .paypal: "p.circle.fill"
        }
    }

    var isAvailable: Bool {
        switch self {
        case .applePurchase: true
        case .applePay: ApplePayService.isAvailable
        case .stripe: true
        case .wechatPay:
            #if os(iOS)
            ThirdPartyPaymentService.shared.isWeChatPayAvailable
            #else
            false
            #endif
        case .alipay: ThirdPartyPaymentService.shared.isAlipayAvailable
        case .paypal: true
        }
    }

    var localizedPrice: String {
        switch self {
        case .applePurchase, .applePay: "¥198"
        case .wechatPay, .alipay: "¥198"
        case .stripe, .paypal: "$29.99"
        }
    }
}
