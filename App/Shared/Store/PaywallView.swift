import DesignSystem
import PassKit
import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?
    @State private var selectedPaymentMethod: PaymentMethod = .applePurchase
    @State private var showSuccessAlert = false

    enum PaymentMethod: String, CaseIterable {
        case applePurchase
        case applePay
        case stripe
        case wechatPay
        case alipay
        case paypal

        var displayName: String {
            switch self {
            case .applePurchase: "App Store"
            case .applePay: "Apple Pay"
            case .stripe: "Stripe"
            case .wechatPay: "微信支付"
            case .alipay: "支付宝"
            case .paypal: "PayPal"
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
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SCTheme.Spacing.xl) {
                    headerSection
                    featuresSection
                    paymentMethodSection
                    pricingSection
                    subscriptionInfoSection
                    restoreButton
                }
                .padding(SCTheme.Spacing.lg)
            }
            .background { BrandBackground() }
            .navigationTitle("pro.title")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("detail.done") { dismiss() }
                    }
                }
                .task {
                    await StoreManager.shared.loadProducts()
                }
                .alert("Error", isPresented: .init(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )) {
                    Button("permission.ok") {}
                } message: {
                    if let error = errorMessage {
                        Text(error)
                    }
                }
                .alert("paywall.success", isPresented: $showSuccessAlert) {
                    Button("permission.ok") { dismiss() }
                }
        }
        #if os(macOS)
        .frame(minWidth: 450, minHeight: 600)
        #endif
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(SCTheme.Gradients.brand)

            Text("pro.title")
                .font(SCTheme.Typography.largeTitle)

            Text("pro.subtitle")
                .font(SCTheme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, SCTheme.Spacing.lg)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: SCTheme.Spacing.md) {
            ForEach(ProFeature.allCases, id: \.rawValue) { feature in
                HStack(spacing: SCTheme.Spacing.md) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(SCTheme.Gradients.brand)
                        .frame(width: 28)

                    Text(feature.displayName)
                        .font(SCTheme.Typography.body)

                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(SCTheme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                .fill(cardFill)
        }
    }

    // MARK: - Payment Method

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
            Text("paywall.paymentMethod")
                .font(SCTheme.Typography.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: SCTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: SCTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: SCTheme.Spacing.sm),
                ],
                spacing: SCTheme.Spacing.sm
            ) {
                ForEach(PaymentMethod.allCases.filter(\.isAvailable), id: \.rawValue) { method in
                    paymentMethodButton(method)
                }
            }
        }
    }

    private func paymentMethodButton(_ method: PaymentMethod) -> some View {
        let isSelected = selectedPaymentMethod == method
        return Button {
            withAnimation(SCTheme.Animation.snappy) {
                selectedPaymentMethod = method
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: method.icon)
                    .font(.system(size: 20))
                Text(method.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SCTheme.Spacing.sm)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.sm)
                    .fill(isSelected ? AnyShapeStyle(SCTheme.Gradients.brand) : AnyShapeStyle(cardFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.sm)
                            .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            if selectedPaymentMethod == .applePurchase {
                storeKitPricingSection
            } else {
                externalPricingSection
            }
        }
    }

    private var storeKitPricingSection: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            if StoreManager.shared.isLoading {
                ProgressView()
                    .padding()
            } else if StoreManager.shared.products.isEmpty {
                VStack(spacing: SCTheme.Spacing.sm) {
                    Text("paywall.productsUnavailable")
                        .font(SCTheme.Typography.body)
                        .foregroundStyle(.secondary)

                    Text("paywall.productsUnavailable.desc")
                        .font(SCTheme.Typography.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                ForEach(StoreManager.shared.products, id: \.id) { product in
                    productCard(product)
                }

                if let selected = selectedProduct {
                    BrandedButton("paywall.subscribe", systemImage: "sparkles") {
                        Task { await purchaseViaStoreKit(selected) }
                    }
                    .disabled(isPurchasing)
                    .padding(.top, SCTheme.Spacing.sm)
                }
            }
        }
    }

    private var externalPricingSection: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            externalProductRow(
                name: "ScrollCap Pro",
                description: "paywall.lifetime.desc",
                price: selectedPaymentMethod.localizedPrice
            )

            BrandedButton("paywall.payNow", systemImage: "creditcard") {
                Task { await purchaseViaExternal() }
            }
            .disabled(isPurchasing)

            if isPurchasing {
                ProgressView()
                    .padding(.top, SCTheme.Spacing.sm)
            }
        }
    }

    private func externalProductRow(name: String, description: LocalizedStringKey, price: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(SCTheme.Typography.headline)
                Text(description)
                    .font(SCTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(price)
                .font(SCTheme.Typography.title)
                .foregroundStyle(SCTheme.Colors.brandBlue)
        }
        .padding(SCTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md)
                .fill(cardFill)
        }
    }

    // MARK: - Subscription Info

    @ViewBuilder
    private var subscriptionInfoSection: some View {
        if let info = StoreManager.shared.subscriptionStatus {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Label {
                    Text("paywall.currentPlan")
                        .font(SCTheme.Typography.headline)
                } icon: {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }

                if let expiration = info.expirationDate {
                    Text("paywall.expires \(expiration, format: .dateTime.month().day().year())")
                        .font(SCTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                if info.isAutoRenewing {
                    Text("paywall.autoRenewOn")
                        .font(SCTheme.Typography.caption)
                        .foregroundStyle(.green)
                }

                Button("paywall.manageSubscription") {
                    Task { await StoreManager.shared.openManageSubscriptions() }
                }
                .font(SCTheme.Typography.callout)
            }
            .padding(SCTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md)
                    .fill(cardFill)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        return Button {
            withAnimation(SCTheme.Animation.snappy) {
                selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(SCTheme.Typography.headline)
                        .foregroundStyle(.primary)
                    Text(product.description)
                        .font(SCTheme.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(SCTheme.Typography.title)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(SCTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md)
                    .fill(isSelected ? AnyShapeStyle(SCTheme.Gradients.brand) : AnyShapeStyle(cardFill))
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md)
                            .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Restore

    @State private var restoreMessage: String?
    @State private var showRestoreAlert = false

    private var restoreButton: some View {
        Button("paywall.restore") {
            Task {
                await StoreManager.shared.restorePurchases()
                if StoreManager.shared.isPro {
                    restoreMessage = String(localized: "paywall.restoreSuccess")
                } else {
                    restoreMessage = String(localized: "paywall.restoreEmpty")
                }
                showRestoreAlert = true
            }
        }
        .font(SCTheme.Typography.caption)
        .foregroundStyle(.secondary)
        .alert("paywall.restore", isPresented: $showRestoreAlert) {
            Button("permission.ok") {
                if StoreManager.shared.isPro { dismiss() }
            }
        } message: {
            if let msg = restoreMessage { Text(msg) }
        }
    }

    // MARK: - Purchase Flows

    private func purchaseViaStoreKit(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await StoreManager.shared.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func purchaseViaExternal() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await executeExternalPayment()
            handlePaymentResult(result)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func executeExternalPayment() async throws -> PaymentResult {
        switch selectedPaymentMethod {
        case .applePay:
            return await ApplePayService.shared.requestPayment(
                amount: 29.99, currency: "CNY", productDescription: "ScrollCap Pro"
            )
        case .stripe:
            return try await StripePaymentService.shared.createCheckoutSession(
                productId: "scrollcap_pro_lifetime", priceInCents: 2999, currency: "usd"
            )
        case .wechatPay:
            return try await ThirdPartyPaymentService.shared.requestWeChatPay(
                productId: "scrollcap_pro_lifetime", amount: 198
            )
        case .alipay:
            return try await ThirdPartyPaymentService.shared.requestAlipay(
                productId: "scrollcap_pro_lifetime", amount: 198
            )
        case .paypal:
            return try await ThirdPartyPaymentService.shared.requestPayPal(
                productId: "scrollcap_pro_lifetime", amount: 29.99, currency: "USD"
            )
        case .applePurchase:
            return .cancelled
        }
    }

    private func handlePaymentResult(_ result: PaymentResult) {
        switch result {
        case .success: showSuccessAlert = true
        case .cancelled: break
        case let .failed(error): errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private var cardFill: some ShapeStyle {
        colorScheme == .dark ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(Color.white.opacity(0.8))
    }
}

private extension PaywallView.PaymentMethod {
    var localizedPrice: String {
        switch self {
        case .applePurchase, .applePay: "¥198"
        case .wechatPay, .alipay: "¥198"
        case .stripe, .paypal: "$29.99"
        }
    }
}
