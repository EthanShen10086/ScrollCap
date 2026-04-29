import SwiftUI
import DesignSystem
import SharedModels

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CaptureViewModel()
    @State private var showPermissionAlert = false
    @State private var showExportSheet = false
    @State private var selectedRegion: CaptureRegion?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                VStack(spacing: SCTheme.Spacing.lg) {
                    Spacer()

                    if let screenshot = viewModel.capturedScreenshot {
                        resultSection(screenshot, in: geometry)
                    } else if let preview = viewModel.currentPreview {
                        previewSection(preview, in: geometry)
                    } else {
                        idleSection
                    }

                    Spacer()

                    captureControls
                    statusBar
                }
                .padding(SCTheme.Spacing.lg)
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
                        viewModel.reset()
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
        .onChange(of: viewModel.capturedScreenshot?.id) { _, newValue in
            if let screenshot = viewModel.capturedScreenshot {
                appState.addScreenshot(screenshot)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
            .ignoresSafeArea()
        #else
        Color(UIColor.systemBackground)
            .ignoresSafeArea()
        #endif
    }

    // MARK: - Idle State

    private var idleSection: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            EmptyStateView(
                systemImage: "scroll",
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
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Label("capture.howItWorks", systemImage: "questionmark.circle")
                    .font(SCTheme.Typography.headline)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
                    Text("capture.step.mac.1")
                    Text("capture.step.mac.2")
                    Text("capture.step.mac.3")
                    Text("capture.step.mac.4")
                }
                .font(SCTheme.Typography.body)
                .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.tertiary)
                    Text("capture.shortcut")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: 400)
    }
    #endif

    #if os(iOS)
    private var iOSInstructions: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Label("capture.howItWorks", systemImage: "questionmark.circle")
                    .font(SCTheme.Typography.headline)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
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
        VStack(spacing: SCTheme.Spacing.sm) {
            Text("capture.livePreview")
                .font(SCTheme.Typography.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: min(geometry.size.width * 0.7, 500))
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
            }
            .frame(maxHeight: geometry.size.height * 0.55)
            .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.lg)
        }
    }

    // MARK: - Result

    private func resultSection(_ screenshot: Screenshot, in geometry: GeometryProxy) -> some View {
        VStack(spacing: SCTheme.Spacing.sm) {
            Text("capture.complete")
                .font(SCTheme.Typography.headline)

            ScrollView {
                Image(decorative: screenshot.image, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: min(geometry.size.width * 0.7, 500))
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
            }
            .frame(maxHeight: geometry.size.height * 0.55)

            HStack(spacing: SCTheme.Spacing.md) {
                Label("\(screenshot.image.width)×\(screenshot.image.height)", systemImage: "ruler")
                Label("capture.frames \(screenshot.metadata.frameCount)", systemImage: "square.stack.3d.up")
                Label(String(format: "%.1fs", screenshot.metadata.durationSeconds), systemImage: "clock")
            }
            .font(SCTheme.Typography.monoCaption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Controls

    private var captureControls: some View {
        HStack(spacing: SCTheme.Spacing.lg) {
            if viewModel.isCapturing {
                CaptureButton(isCapturing: true) {
                    Task { await viewModel.stopCapture() }
                }

                Button("capture.cancel", role: .destructive) {
                    viewModel.cancelCapture()
                }
                .buttonStyle(.bordered)
            } else if viewModel.capturedScreenshot == nil {
                CaptureButton(isCapturing: false) {
                    Task { await viewModel.startCapture(region: selectedRegion) }
                }
            }
        }
        .padding()
        .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.xl)
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        switch viewModel.captureState {
        case .idle:
            StatusPill(String(localized: "status.ready"), color: SCTheme.Colors.captureReady)
        case .selectingRegion:
            StatusPill(String(localized: "status.selectRegion"), color: .orange)
        case .preparing:
            StatusPill(String(localized: "status.preparing"), color: .orange)
        case .capturing(let progress):
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
        case .completed(let count):
            StatusPill(String(localized: "status.done \(count)"), color: SCTheme.Colors.captureDone)
        case .failed(let message):
            StatusPill(message, color: SCTheme.Colors.destructive)
        }
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
                            Slider(value: $quality, in: 0.1...1.0, step: 0.05)
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
                    ShareLink(item: Image(decorative: screenshot.image, scale: 1.0), preview: SharePreview(Text("export.sharePreview"))) {
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

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            try await viewModel.exportScreenshot(options: options, to: url)
            dismiss()
        } catch {
            // Export failed
        }
        #elseif os(iOS)
        do {
            if let data = try await viewModel.exportToData(options: options) {
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(
                    "ScrollCap_\(Int(Date().timeIntervalSince1970)).\(selectedFormat.fileExtension)"
                )
                try data.write(to: tempURL)
                dismiss()
            }
        } catch {
            // Export failed
        }
        #endif
    }
}

#if os(iOS)
struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: SCTheme.Spacing.sm) {
            Text("\(number)")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(SCTheme.Typography.body)
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}
#endif
