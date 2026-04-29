import DesignSystem
import SharedModels
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.userMode) private var userMode

    var body: some View {
        @Bindable var state = self.appState
        Form {
            // MARK: - User Mode Selection

            Section {
                self.userModePicker
            } header: {
                Text("settings.mode")
            } footer: {
                Text(self.appState.userMode.description)
            }

            // MARK: - Minor Mode: Usage Limit

            if self.appState.isMinorMode {
                Section("settings.minor") {
                    Stepper(
                        "settings.minor.limit \(self.appState.minorUsageLimitMinutes)",
                        value: $state.minorUsageLimitMinutes,
                        in: 15 ... 120,
                        step: 5
                    )

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
                        Text("settings.minor.sessionTime \(self.appState.sessionMinutesUsed)")
                            .font(SCTheme.Typography.body)
                    }

                    Button("settings.minor.resetSession") {
                        self.appState.resetSession()
                    }
                }
            }

            Section("settings.export") {
                Picker("export.format", selection: $state.exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }

                if self.appState.exportFormat.supportedCompressionQuality {
                    VStack(alignment: .leading) {
                        Text("export.quality \(Int(self.appState.exportQuality * 100))")
                        Slider(value: $state.exportQuality, in: 0.1 ... 1.0, step: 0.05)
                    }
                }
            }

            Section("settings.capture") {
                #if os(macOS)
                self.macOSCaptureSettings
                #else
                self.iOSCaptureSettings
                #endif

                Toggle("settings.autoScroll", isOn: $state.autoScrollEnabled)

                Text("settings.autoScroll.desc")
                    .font(self.adaptiveCaption)
                    .foregroundStyle(.secondary)
            }

            Section("settings.sync") {
                Toggle("settings.iCloudSync", isOn: $state.iCloudSyncEnabled)
                    .onChange(of: self.appState.iCloudSyncEnabled) { _, enabled in
                        if enabled {
                            ICloudSyncManager.shared.startMonitoring()
                        } else {
                            ICloudSyncManager.shared.stopMonitoring()
                        }
                        AnalyticsManager.shared.track(.settingsChanged(key: "icloud_sync", value: "\(enabled)"))
                    }

                if ICloudSyncManager.shared.isAvailable {
                    HStack {
                        Circle()
                            .fill(self.syncStatusColor)
                            .frame(width: 8, height: 8)
                        Text(self.syncStatusText)
                            .font(self.adaptiveCaption)
                    }
                }

                Text("settings.iCloudSync.desc")
                    .font(self.adaptiveCaption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Pro (hidden in Minor mode)

            if !self.appState.shouldHidePayment {
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
            }

            Section("settings.about") {
                LabeledContent("settings.version", value: "1.0.0")
                LabeledContent("settings.build", value: "1")

                if !self.appState.isMinorMode {
                    Link(destination: URL(string: "https://github.com/EthanShen10086/ScrollCap")!) {
                        Label("settings.sourceCode", systemImage: "curlybraces")
                    }
                }
            }
        }
        .navigationTitle("nav.settings")
        #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 400, minHeight: 300)
        #endif
    }

    // MARK: - User Mode Picker

    private var userModePicker: some View {
        @Bindable var state = self.appState
        return Picker("settings.mode.select", selection: $state.userMode) {
            ForEach(UserMode.allCases) { mode in
                Label(mode.displayName, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        #if os(iOS)
        .pickerStyle(.navigationLink)
        #endif
    }

    private var adaptiveCaption: Font {
        self.appState.isElderMode ? .body : SCTheme.Typography.caption
    }

    #if os(macOS)
    private var macOSCaptureSettings: some View {
        Group {
            LabeledContent("settings.captureMethod", value: String(localized: "method.screenCaptureKit"))
            Toggle("settings.showCursor", isOn: .constant(false))
            LabeledContent("settings.frameRate", value: String(localized: "settings.frameRate.value"))
        }
    }
    #endif

    #if os(iOS)
    private var iOSCaptureSettings: some View {
        Group {
            LabeledContent("settings.captureMethod", value: String(localized: "method.replayKit"))
            Text("settings.ios.captureDesc")
                .font(self.adaptiveCaption)
                .foregroundStyle(.secondary)
        }
    }
    #endif

    private var syncStatusColor: Color {
        switch ICloudSyncManager.shared.syncState {
        case .idle: .secondary
        case .syncing: .orange
        case .synced: .green
        case .error: .red
        case .disabled: .gray
        }
    }

    private var syncStatusText: LocalizedStringKey {
        switch ICloudSyncManager.shared.syncState {
        case .idle: "icloud.status.idle"
        case .syncing: "icloud.status.syncing"
        case .synced: "icloud.status.synced"
        case .error: "icloud.status.error"
        case .disabled: "icloud.status.disabled"
        }
    }
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
                    self.proFeatureRow(
                        icon: "text.viewfinder",
                        title: "pro.feature.ocr",
                        description: "pro.feature.ocr.desc"
                    )
                    self.proFeatureRow(
                        icon: "arrow.up.and.down.text.horizontal",
                        title: "pro.feature.autoScroll",
                        description: "pro.feature.autoScroll.desc"
                    )
                    self.proFeatureRow(
                        icon: "icloud",
                        title: "pro.feature.iCloud",
                        description: "pro.feature.iCloud.desc"
                    )
                    self.proFeatureRow(
                        icon: "photo.badge.plus",
                        title: "pro.feature.formats",
                        description: "pro.feature.formats.desc"
                    )
                }
                .padding(SCTheme.Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                        .fill(self.colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.8))
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
