import SwiftUI
import DesignSystem
import SharedModels

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState
        Form {
            Section("settings.export") {
                Picker("export.format", selection: $state.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }

                if appState.exportFormat.supportedCompressionQuality {
                    VStack(alignment: .leading) {
                        Text("export.quality \(Int(appState.exportQuality * 100))")
                        Slider(value: $state.exportQuality, in: 0.1...1.0, step: 0.05)
                    }
                }
            }

            Section("settings.capture") {
                #if os(macOS)
                macOSCaptureSettings
                #else
                iOSCaptureSettings
                #endif

                Toggle("settings.autoScroll", isOn: $state.autoScrollEnabled)

                Text("settings.autoScroll.desc")
                    .font(SCTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Section("settings.sync") {
                Toggle("settings.iCloudSync", isOn: $state.iCloudSyncEnabled)

                Text("settings.iCloudSync.desc")
                    .font(SCTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                NavigationLink {
                    ProUpgradeTeaser()
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(SCTheme.Gradients.brand)
                        Text("settings.pro")
                            .fontWeight(.medium)
                        Spacer()
                        Text("settings.pro.badge")
                            .font(SCTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(SCTheme.Gradients.brand, in: Capsule())
                    }
                }
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: "1.0.0")
                LabeledContent("settings.build", value: "1")

                Link(destination: URL(string: "https://github.com/EthanShen10086/ScrollCap")!) {
                    Label("settings.sourceCode", systemImage: "curlybraces")
                }
            }
        }
        .navigationTitle("nav.settings")
        #if os(macOS)
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    #if os(macOS)
    private var macOSCaptureSettings: some View {
        Group {
            LabeledContent("settings.captureMethod", value: String(localized: "method.screenCaptureKit"))
            Toggle("settings.showCursor", isOn: .constant(false))
            LabeledContent("settings.frameRate", value: "10 fps")
        }
    }
    #endif

    #if os(iOS)
    private var iOSCaptureSettings: some View {
        Group {
            LabeledContent("settings.captureMethod", value: String(localized: "method.replayKit"))
            Text("settings.ios.captureDesc")
                .font(SCTheme.Typography.caption)
                .foregroundStyle(.secondary)
        }
    }
    #endif
}

// MARK: - Pro Upgrade Teaser

struct ProUpgradeTeaser: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: SCTheme.Spacing.xl) {
                VStack(spacing: SCTheme.Spacing.md) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(SCTheme.Gradients.brand)

                    Text("pro.title")
                        .font(SCTheme.Typography.largeTitle)

                    Text("pro.subtitle")
                        .font(SCTheme.Typography.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: SCTheme.Spacing.md) {
                    proFeatureRow(icon: "text.viewfinder", title: "pro.feature.ocr", description: "pro.feature.ocr.desc")
                    proFeatureRow(icon: "arrow.up.and.down.text.horizontal", title: "pro.feature.autoScroll", description: "pro.feature.autoScroll.desc")
                    proFeatureRow(icon: "icloud", title: "pro.feature.iCloud", description: "pro.feature.iCloud.desc")
                    proFeatureRow(icon: "photo.badge.plus", title: "pro.feature.formats", description: "pro.feature.formats.desc")
                }
                .padding(SCTheme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.8))
                }

                BrandedButton("pro.upgrade", systemImage: "sparkles") {
                    // Triggers paywall (Phase 8)
                }
                .padding(.top, SCTheme.Spacing.md)
            }
            .padding(SCTheme.Spacing.xl)
        }
        .background { BrandBackground() }
        .navigationTitle("pro.title")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func proFeatureRow(icon: String, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: SCTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(SCTheme.Gradients.brand)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SCTheme.Typography.headline)
                Text(description)
                    .font(SCTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
