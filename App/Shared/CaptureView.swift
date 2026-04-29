import DesignSystem
import SharedModels
import SwiftUI

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.platformMetrics) private var metrics
    @Environment(\.userMode) private var userMode
    @State private var viewModel = CaptureViewModel()
    @State private var showPermissionAlert = false
    @State private var showExportSheet = false
    @State private var selectedRegion: CaptureRegion?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BrandBackground()

                VStack(spacing: 0) {
                    if appState.showUsageWarning {
                        UsageTimerBanner(
                            minutesUsed: appState.sessionMinutesUsed,
                            limitMinutes: appState.minorUsageLimitMinutes,
                            onDismiss: { appState.dismissUsageWarning() }
                        )
                        .padding(.top, SCTheme.Spacing.sm)
                    }

                    Spacer()

                    contentArea(in: geometry)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                        .animation(
                            userMode == .elder ? nil : SCTheme.Animation.gentle,
                            value: viewModel.captureState.isCapturing
                        )
                        .animation(
                            userMode == .elder ? nil : SCTheme.Animation.gentle,
                            value: viewModel.capturedScreenshot?.id
                        )

                    Spacer()

                    controlBar(in: geometry)
                        .padding(.bottom, SCTheme.Spacing.lg)
                }
                .padding(.horizontal, metrics.defaultPadding)
            }
        }
        .navigationTitle("capture.title")
        .toolbar {
            ToolbarItemGroup {
                if viewModel.capturedScreenshot != nil {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("export.title", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        withAnimation(SCTheme.Animation.spring) {
                            viewModel.reset()
                        }
                    } label: {
                        Label("capture.new", systemImage: "plus")
                    }
                }
            }
        }
        .alert("permission.title", isPresented: $showPermissionAlert) {
            Button("permission.ok") {}
        } message: {
            Text("permission.message")
        }
        .sheet(isPresented: $showExportSheet) {
            if let screenshot = viewModel.capturedScreenshot {
                ExportSheet(screenshot: screenshot, viewModel: viewModel)
            }
        }
        .task {
            let hasPermission = await viewModel.requestPermission()
            if !hasPermission {
                showPermissionAlert = true
            }
        }
        .onChange(of: viewModel.capturedScreenshot?.id) { _, _ in
            if let screenshot = viewModel.capturedScreenshot {
                appState.addScreenshot(screenshot)
            }
        }
        .alert(
            "error.title",
            isPresented: .init(
                get: { ErrorPresenter.shared.isPresented },
                set: { if !$0 { ErrorPresenter.shared.dismiss() } }
            )
        ) {
            Button("permission.ok") { ErrorPresenter.shared.dismiss() }
        } message: {
            if let error = ErrorPresenter.shared.currentError {
                Text(error.userMessage)
            }
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private func contentArea(in geometry: GeometryProxy) -> some View {
        if let screenshot = viewModel.capturedScreenshot {
            resultSection(screenshot, in: geometry)
        } else if let preview = viewModel.currentPreview {
            previewSection(preview, in: geometry)
        } else {
            idleSection
        }
    }

    // MARK: - Idle State

    private var idleSection: some View {
        VStack(spacing: SCTheme.Spacing.xl) {
            EmptyStateView(
                systemImage: "camera.viewfinder",
                title: String(localized: "capture.ready"),
                description: platformDescription
            )

            #if os(macOS)
            macOSInstructions
            #else
            iOSInstructions
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var platformDescription: String {
        #if os(macOS)
        String(localized: "capture.ready.desc.mac")
        #else
        String(localized: "capture.ready.desc.ios")
        #endif
    }

    #if os(macOS)
    private var macOSInstructions: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.md) {
                Label("capture.howItWorks", systemImage: "questionmark.circle")
                    .font(SCTheme.Typography.headline)
                    .foregroundStyle(SCTheme.Gradients.brand)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                    InstructionRow(number: 1, text: String(localized: "capture.step.mac.1"))
                    InstructionRow(number: 2, text: String(localized: "capture.step.mac.2"))
                    InstructionRow(number: 3, text: String(localized: "capture.step.mac.3"))
                    InstructionRow(number: 4, text: String(localized: "capture.step.mac.4"))
                }

                HStack(spacing: SCTheme.Spacing.sm) {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.tertiary)
                    Text("capture.shortcut")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, SCTheme.Spacing.xs)
            }
        }
        .frame(maxWidth: 420)
    }
    #endif

    #if os(iOS)
    private var iOSInstructions: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.md) {
                Label("capture.howItWorks", systemImage: "questionmark.circle")
                    .font(SCTheme.Typography.headline)
                    .foregroundStyle(SCTheme.Gradients.brand)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                    InstructionRow(number: 1, text: String(localized: "capture.step.ios.1"))
                    InstructionRow(number: 2, text: String(localized: "capture.step.ios.2"))
                    InstructionRow(number: 3, text: String(localized: "capture.step.ios.3"))
                    InstructionRow(number: 4, text: String(localized: "capture.step.ios.4"))
                }
            }
        }
        .frame(maxWidth: 400)
    }
    #endif

    // MARK: - Preview

    private func previewSection(_ image: CGImage, in geometry: GeometryProxy) -> some View {
        VStack(spacing: SCTheme.Spacing.md) {
            HStack {
                Circle()
                    .fill(SCTheme.Colors.captureActive)
                    .frame(width: 8, height: 8)

                Text("capture.livePreview")
                    .font(SCTheme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: min(geometry.size.width * 0.7, metrics.capturePreviewMaxWidth))
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                    .accessibilityLabel(String(localized: "capture.livePreview"))
            }
            .frame(maxHeight: geometry.size.height * 0.55)
        }
        .padding(SCTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: SCTheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
        }
    }

    // MARK: - Result

    private func resultSection(_ screenshot: Screenshot, in geometry: GeometryProxy) -> some View {
        VStack(spacing: SCTheme.Spacing.md) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(SCTheme.Colors.captureDone)
                Text("capture.complete")
                    .font(SCTheme.Typography.headline)
            }

            ScrollView {
                Image(decorative: screenshot.image, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: min(geometry.size.width * 0.7, metrics.capturePreviewMaxWidth))
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    .accessibilityLabel(String(localized: "capture.complete"))
                    .accessibilityHint("\(screenshot.image.width)×\(screenshot.image.height)")
            }
            .frame(maxHeight: geometry.size.height * 0.5)

            HStack(spacing: SCTheme.Spacing.lg) {
                metadataBadge(icon: "ruler", value: "\(screenshot.image.width)×\(screenshot.image.height)")
                metadataBadge(icon: "square.stack.3d.up", value: "\(screenshot.metadata.frameCount)")
                metadataBadge(icon: "clock", value: String(format: "%.1fs", screenshot.metadata.durationSeconds))
            }
        }
        .padding(SCTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: SCTheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
        }
    }

    private func metadataBadge(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(value)
                .font(SCTheme.Typography.monoCaption)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary.opacity(0.5), in: Capsule())
    }

    // MARK: - Control Bar

    private func controlBar(in geometry: GeometryProxy) -> some View {
        VStack(spacing: SCTheme.Spacing.md) {
            HStack(spacing: SCTheme.Spacing.xl) {
                if viewModel.isCapturing {
                    Button {
                        viewModel.cancelCapture()
                    } label: {
                        if userMode == .elder {
                            Label("capture.cancel", systemImage: "xmark")
                                .font(.title3.weight(.medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial, in: Capsule())
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .transition(.scale.combined(with: .opacity))

                    adaptiveCaptureButton(isCapturing: true) {
                        Task { await viewModel.stopCapture() }
                    }
                } else if viewModel.capturedScreenshot == nil {
                    adaptiveCaptureButton(isCapturing: false) {
                        Task { await viewModel.startCapture(region: selectedRegion) }
                    }
                }
            }
            .animation(
                userMode == .elder ? .easeInOut(duration: 0.2) : SCTheme.Animation.spring,
                value: viewModel.isCapturing
            )

            statusIndicator
        }
    }

    @ViewBuilder
    private func adaptiveCaptureButton(isCapturing: Bool, action: @escaping () -> Void) -> some View {
        if userMode == .elder {
            ElderCaptureButton(isCapturing: isCapturing, action: action)
        } else {
            CaptureButton(isCapturing: isCapturing, action: action)
        }
    }

    // MARK: - Status

    private var statusIndicator: some View {
        Group {
            switch viewModel.captureState {
            case .idle:
                StatusPill(String(localized: "status.ready"), color: SCTheme.Colors.captureReady)
            case .selectingRegion:
                StatusPill(String(localized: "status.selectRegion"), color: .orange)
            case .preparing:
                StatusPill(String(localized: "status.preparing"), color: .orange)
            case let .capturing(progress):
                HStack(spacing: SCTheme.Spacing.sm) {
                    StatusPill(String(localized: "status.recording"), color: SCTheme.Colors.captureActive)
                    Text("capture.frames \(progress.capturedFrames)")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.secondary)
                }
            case .stitching:
                HStack(spacing: SCTheme.Spacing.sm) {
                    ProgressView()
                        .controlSize(.small)
                    StatusPill(String(localized: "status.stitching"), color: .purple)
                }
            case let .completed(count):
                StatusPill(String(localized: "status.done \(count)"), color: SCTheme.Colors.captureDone)
            case let .failed(message):
                StatusPill(message, color: SCTheme.Colors.destructive)
            }
        }
        .transition(.opacity)
        .animation(SCTheme.Animation.standard, value: viewModel.captureState.statusKey)
    }
}

// MARK: - Export Sheet

struct ExportSheet: View {
    let screenshot: Screenshot
    let viewModel: CaptureViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .png
    @State private var quality: Double = 0.9
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("export.format") {
                    Picker("export.format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedFormat.supportedCompressionQuality {
                        VStack(alignment: .leading) {
                            Text("export.quality \(Int(quality * 100))")
                            Slider(value: $quality, in: 0.1 ... 1.0, step: 0.05)
                        }
                    }
                }

                Section("export.info") {
                    LabeledContent("export.dimensions", value: "\(screenshot.image.width)×\(screenshot.image.height)")
                    LabeledContent("export.frames", value: "\(screenshot.metadata.frameCount)")
                }

                Section {
                    Button {
                        Task { await saveImage() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("export.save", systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)

                    #if os(iOS)
                    ShareLink(
                        item: Image(decorative: screenshot.image, scale: 1.0),
                        preview: SharePreview(Text("export.sharePreview"))
                    ) {
                        HStack {
                            Spacer()
                            Label("export.share", systemImage: "square.and.arrow.up")
                            Spacer()
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("export.title")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("capture.cancel") { dismiss() }
                    }
                }
        }
        #if os(macOS)
        .frame(minWidth: 350, minHeight: 300)
        #endif
    }

    private func saveImage() async {
        isSaving = true
        defer { isSaving = false }

        let options = ExportOptions(format: selectedFormat, compressionQuality: quality)

        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [selectedFormat.utType]
        panel.nameFieldStringValue = "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(selectedFormat.fileExtension)"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            try await viewModel.exportScreenshot(options: options, to: url)
            AnalyticsManager.shared.track(.exportSaved(format: selectedFormat.fileExtension))
            dismiss()
        } catch {
            ErrorPresenter.shared.present(.export(.fileWriteFailed))
        }
        #elseif os(iOS)
        do {
            if let data = try await viewModel.exportToData(options: options) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                    "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(selectedFormat.fileExtension)"
                )
                try data.write(to: tempURL)
                AnalyticsManager.shared.track(.exportSaved(format: selectedFormat.fileExtension))
                dismiss()
            }
        } catch {
            ErrorPresenter.shared.present(.export(.fileWriteFailed))
        }
        #endif
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: SCTheme.Spacing.sm) {
            Text("\(number)")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(SCTheme.Gradients.brand, in: Circle())

            Text(text)
                .font(SCTheme.Typography.body)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}
