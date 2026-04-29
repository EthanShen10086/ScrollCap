import SwiftUI
import DesignSystem

enum ProFeature: String, CaseIterable {
    case ocr = "OCR"
    case autoScroll = "AutoScroll"
    case iCloudSync = "iCloudSync"
    case advancedExport = "AdvancedExport"

    var displayName: LocalizedStringKey {
        switch self {
        case .ocr: "pro.feature.ocr"
        case .autoScroll: "pro.feature.autoScroll"
        case .iCloudSync: "pro.feature.iCloud"
        case .advancedExport: "pro.feature.formats"
        }
    }

    var icon: String {
        switch self {
        case .ocr: "text.viewfinder"
        case .autoScroll: "arrow.up.and.down.text.horizontal"
        case .iCloudSync: "icloud"
        case .advancedExport: "photo.badge.plus"
        }
    }
}

struct ProFeatureGate: ViewModifier {
    let feature: ProFeature
    @State private var showPaywall = false

    func body(content: Content) -> some View {
        if StoreManager.shared.isPro {
            content
        } else {
            content
                .overlay {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        VStack(spacing: SCTheme.Spacing.md) {
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundStyle(SCTheme.Gradients.brand)

                            Text(feature.displayName)
                                .font(SCTheme.Typography.headline)

                            BrandedButton("pro.upgrade", systemImage: "sparkles") {
                                showPaywall = true
                                AnalyticsManager.shared.track(.proUpgradeTapped)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showPaywall) {
                    PaywallView()
                }
        }
    }
}

extension View {
    func requiresPro(_ feature: ProFeature) -> some View {
        modifier(ProFeatureGate(feature: feature))
    }
}
