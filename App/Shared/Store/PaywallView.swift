import SwiftUI
import StoreKit
import DesignSystem

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SCTheme.Spacing.xl) {
                    headerSection
                    featuresSection
                    pricingSection
                    externalPaymentNote
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
                .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.8))
        }
    }

    // MARK: - Pricing

    private var pricingSection: some View {
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
                        Task { await purchase(selected) }
                    }
                    .disabled(isPurchasing)
                    .padding(.top, SCTheme.Spacing.sm)
                }
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
                    .fill(isSelected ? AnyShapeStyle(SCTheme.Gradients.brand) : AnyShapeStyle(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.8)))
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md)
                            .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - External Payment Providers

    private var externalPaymentNote: some View {
        VStack(spacing: SCTheme.Spacing.sm) {
            Text("paywall.externalPayments")
                .font(SCTheme.Typography.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: SCTheme.Spacing.lg) {
                externalBadge("WeChat Pay")
                externalBadge("Alipay")
                externalBadge("PayPal")
                externalBadge("Stripe")
            }
        }
        .padding(.top, SCTheme.Spacing.sm)
    }

    private func externalBadge(_ name: String) -> some View {
        Text(name)
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.quaternary.opacity(0.5), in: Capsule())
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button("paywall.restore") {
            Task { await StoreManager.shared.restorePurchases() }
        }
        .font(SCTheme.Typography.caption)
        .foregroundStyle(.secondary)
    }

    // MARK: - Purchase

    private func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let success = try await StoreManager.shared.purchase(product)
            if success { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - External Payment Provider Protocol

protocol ExternalPaymentProvider {
    var name: String { get }
    var isAvailable: Bool { get }
    func initiatePayment(amount: Decimal, currency: String, productId: String) async throws -> PaymentResult
}

enum PaymentResult {
    case success(transactionId: String)
    case cancelled
    case failed(Error)
}

struct WeChatPayProvider: ExternalPaymentProvider {
    let name = "WeChat Pay"
    var isAvailable: Bool { false }

    func initiatePayment(amount: Decimal, currency: String, productId: String) async throws -> PaymentResult {
        .cancelled
    }
}

struct AlipayProvider: ExternalPaymentProvider {
    let name = "Alipay"
    var isAvailable: Bool { false }

    func initiatePayment(amount: Decimal, currency: String, productId: String) async throws -> PaymentResult {
        .cancelled
    }
}

struct StripeProvider: ExternalPaymentProvider {
    let name = "Stripe"
    var isAvailable: Bool { false }

    func initiatePayment(amount: Decimal, currency: String, productId: String) async throws -> PaymentResult {
        .cancelled
    }
}

struct PayPalProvider: ExternalPaymentProvider {
    let name = "PayPal"
    var isAvailable: Bool { false }

    func initiatePayment(amount: Decimal, currency: String, productId: String) async throws -> PaymentResult {
        .cancelled
    }
}
