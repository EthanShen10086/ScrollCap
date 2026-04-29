import DesignSystem
import SwiftUI

enum ProFeature: String, CaseIterable {
    case ocr = "OCR"
    case autoScroll = "AutoScroll"
    case iCloudSync
    case advancedExport = "AdvancedExport"
    case imageEditor = "ImageEditor"

    var displayName: LocalizedStringKey {
        switch self {
        case .ocr: "pro.feature.ocr"
        case .autoScroll: "pro.feature.autoScroll"
        case .iCloudSync: "pro.feature.iCloud"
        case .advancedExport: "pro.feature.formats"
        case .imageEditor: "pro.feature.editor"
        }
    }

    var icon: String {
        switch self {
        case .ocr: "text.viewfinder"
        case .autoScroll: "arrow.up.and.down.text.horizontal"
        case .iCloudSync: "icloud"
        case .advancedExport: "photo.badge.plus"
        case .imageEditor: "pencil.and.outline"
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

                            Text(self.feature.displayName)
                                .font(SCTheme.Typography.headline)

                            BrandedButton("pro.upgrade", systemImage: "sparkles") {
                                self.showPaywall = true
                                AnalyticsManager.shared.track(.proUpgradeTapped)
                            }
                        }
                    }
                }
                .sheet(isPresented: self.$showPaywall) {
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
