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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SCTheme.Spacing.xl) {
                    self.headerSection
                    self.featuresSection
                    self.paymentMethodSection
                    self.pricingSection
                    self.subscriptionInfoSection
                    self.restoreButton
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
                        Button("detail.done") { self.dismiss() }
                    }
                }
                .task {
                    await StoreManager.shared.loadProducts()
                }
                .alert("error.title", isPresented: .init(
                    get: { self.errorMessage != nil },
                    set: { if !$0 { self.errorMessage = nil } }
                )) {
                    Button("permission.ok") {}
                } message: {
                    if let error = errorMessage {
                        Text(error)
                    }
                }
                .alert("paywall.success", isPresented: self.$showSuccessAlert) {
                    Button("permission.ok") { self.dismiss() }
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
                .fill(self.cardFill)
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
                    self.paymentMethodButton(method)
                }
            }
        }
    }

    private func paymentMethodButton(_ method: PaymentMethod) -> some View {
        let isSelected = self.selectedPaymentMethod == method
        return Button {
            withAnimation(SCTheme.Animation.snappy) {
                self.selectedPaymentMethod = method
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
                    .fill(isSelected ? AnyShapeStyle(SCTheme.Gradients.brand) : AnyShapeStyle(self.cardFill))
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
            if self.selectedPaymentMethod == .applePurchase {
                self.storeKitPricingSection
            } else {
                self.externalPricingSection
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
                    self.productCard(product)
                }

                if let selected = selectedProduct {
                    BrandedButton("paywall.subscribe", systemImage: "sparkles") {
                        Task { await self.purchaseViaStoreKit(selected) }
                    }
                    .disabled(self.isPurchasing)
                    .padding(.top, SCTheme.Spacing.sm)
                }
            }
        }
    }

    private var externalPricingSection: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            self.externalProductRow(
                name: String(localized: "pro.title"),
                description: "paywall.lifetime.desc",
                price: self.selectedPaymentMethod.localizedPrice
            )

            BrandedButton("paywall.payNow", systemImage: "creditcard") {
                Task { await self.purchaseViaExternal() }
            }
            .disabled(self.isPurchasing)

            if self.isPurchasing {
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
                .fill(self.cardFill)
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
                    .fill(self.cardFill)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = self.selectedProduct?.id == product.id
        return Button {
            withAnimation(SCTheme.Animation.snappy) {
                self.selectedProduct = product
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
                    .fill(isSelected ? AnyShapeStyle(SCTheme.Gradients.brand) : AnyShapeStyle(self.cardFill))
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
                if EntitlementManager.shared.isPro {
                    self.restoreMessage = String(localized: "paywall.restoreSuccess")
                } else {
                    self.restoreMessage = String(localized: "paywall.restoreEmpty")
                }
                self.showRestoreAlert = true
            }
        }
        .font(SCTheme.Typography.caption)
        .foregroundStyle(.secondary)
        .alert("paywall.restore", isPresented: self.$showRestoreAlert) {
            Button("permission.ok") {
                if EntitlementManager.shared.isPro { self.dismiss() }
            }
        } message: {
            if let msg = restoreMessage { Text(msg) }
        }
    }

    // MARK: - Purchase Flows

    private func purchaseViaStoreKit(_ product: Product) async {
        self.isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await StoreManager.shared.purchase(product)
            if success { self.dismiss() }
        } catch {
            self.errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(.purchaseFailed(productId: product.id, error: error.localizedDescription))
        }
    }

    private func purchaseViaExternal() async {
        self.isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await executeExternalPayment()
            self.handlePaymentResult(result)
        } catch {
            self.errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(.purchaseFailed(
                productId: self.selectedPaymentMethod.rawValue,
                error: error.localizedDescription
            ))
        }
    }

    private func executeExternalPayment() async throws -> PaymentResult {
        switch self.selectedPaymentMethod {
        case .applePay:
            return await ApplePayService.shared.requestPayment(
                amount: 29.99, currency: "CNY", productDescription: String(localized: "pro.title")
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
        let methodId = self.selectedPaymentMethod.rawValue
        switch result {
        case let .success(transactionId):
            let source = self.entitlementSource(for: self.selectedPaymentMethod)
            EntitlementManager.shared.onThirdPartyPaymentVerified(source: source, transactionId: transactionId)
            self.showSuccessAlert = true
            AnalyticsManager.shared.track(.purchaseCompleted(productId: methodId))
        case .cancelled:
            AnalyticsManager.shared.track(.purchaseCancelled(productId: methodId))
        case let .failed(error):
            self.errorMessage = error.localizedDescription
            AnalyticsManager.shared.track(.purchaseFailed(productId: methodId, error: error.localizedDescription))
        }
    }

    private func entitlementSource(for method: PaymentMethod) -> EntitlementSource {
        switch method {
        case .applePurchase: return .appStoreIAP
        case .applePay: return .applePay
        case .stripe: return .stripe
        case .wechatPay: return .wechatPay
        case .alipay: return .alipay
        case .paypal: return .paypal
        }
    }

    // MARK: - Helpers

    private var cardFill: some ShapeStyle {
        self.colorScheme == .dark ? AnyShapeStyle(Color.white.opacity(0.05)) : AnyShapeStyle(Color.white.opacity(0.8))
    }
}
