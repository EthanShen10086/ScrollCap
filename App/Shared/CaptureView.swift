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
        .navigationTitle("Capture")
        .toolbar {
            ToolbarItemGroup {
                if viewModel.capturedScreenshot != nil {
                    Button {
                        showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        viewModel.reset()
                    } label: {
                        Label("New Capture", systemImage: "plus")
                    }
                }
            }
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK") {}
        } message: {
            Text("ScrollCap needs screen recording permission. Please grant access in System Settings > Privacy & Security > Screen Recording.")
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
                title: "Ready to Capture",
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
        "Select a region on screen, then scroll to capture a long screenshot."
        #else
        "Start recording, switch to the target app, and scroll to capture."
        #endif
    }

    #if os(macOS)
    private var macOSInstructions: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Label("How it works", systemImage: "questionmark.circle")
                    .font(SCTheme.Typography.headline)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
                    Text("1. Click the capture button")
                    Text("2. Select the screen region to capture")
                    Text("3. Scroll through the content slowly")
                    Text("4. Click stop to finish and stitch")
                }
                .font(SCTheme.Typography.body)
                .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.tertiary)
                    Text("Shortcut: ⌘⇧6")
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
                Label("How it works", systemImage: "questionmark.circle")
                    .font(SCTheme.Typography.headline)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
                    InstructionRow(number: 1, text: "Tap the capture button")
                    InstructionRow(number: 2, text: "Switch to the target app")
                    InstructionRow(number: 3, text: "Scroll slowly through the content")
                    InstructionRow(number: 4, text: "Return here and tap stop")
                }
            }
        }
        .frame(maxWidth: 400)
    }
    #endif

    // MARK: - Preview

    private func previewSection(_ image: CGImage, in geometry: GeometryProxy) -> some View {
        VStack(spacing: SCTheme.Spacing.sm) {
            Text("Live Preview")
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
            Text("Capture Complete")
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
                Label("\(screenshot.metadata.frameCount) frames", systemImage: "square.stack.3d.up")
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

                Button("Cancel", role: .destructive) {
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
            StatusPill("Ready", color: SCTheme.Colors.captureReady)
        case .selectingRegion:
            StatusPill("Select Region", color: .orange)
        case .preparing:
            StatusPill("Preparing...", color: .orange)
        case .capturing(let progress):
            HStack(spacing: SCTheme.Spacing.sm) {
                StatusPill("Recording", color: SCTheme.Colors.captureActive)
                Text("\(progress.capturedFrames) frames")
                    .font(SCTheme.Typography.monoCaption)
                    .foregroundStyle(.secondary)
            }
        case .stitching:
            HStack(spacing: SCTheme.Spacing.sm) {
                ProgressView()
                    .controlSize(.small)
                StatusPill("Stitching...", color: .purple)
            }
        case .completed(let count):
            StatusPill("Done (\(count) frames)", color: SCTheme.Colors.captureDone)
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
                Section("Format") {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedFormat.supportedCompressionQuality {
                        VStack(alignment: .leading) {
                            Text("Quality: \(Int(quality * 100))%")
                            Slider(value: $quality, in: 0.1...1.0, step: 0.05)
                        }
                    }
                }

                Section("Info") {
                    LabeledContent("Dimensions", value: "\(screenshot.image.width)×\(screenshot.image.height)")
                    LabeledContent("Frames", value: "\(screenshot.metadata.frameCount)")
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
                                Label("Save", systemImage: "square.and.arrow.down")
                            }
                            Spacer()
                        }
                    }
                    .disabled(isSaving)

                    #if os(iOS)
                    ShareLink(item: Image(decorative: screenshot.image, scale: 1.0), preview: SharePreview("ScrollCap Screenshot")) {
                        HStack {
                            Spacer()
                            Label("Share", systemImage: "square.and.arrow.up")
                            Spacer()
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("Export")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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
