import DesignSystem
import SharedModels
import SwiftUI

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.platformMetrics) private var metrics
    @Environment(\.userMode) private var userMode
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = CaptureViewModel()

    private var shouldReduceMotion: Bool {
        self.reduceMotion || self.userMode == .elder
    }

    @State private var showPermissionAlert = false
    @State private var showExportSheet = false
    @State private var selectedRegion: CaptureRegion?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                BrandBackground()

                VStack(spacing: 0) {
                    if self.appState.showUsageWarning {
                        UsageTimerBanner(
                            minutesUsed: self.appState.sessionMinutesUsed,
                            limitMinutes: self.appState.minorUsageLimitMinutes,
                            onDismiss: { self.appState.dismissUsageWarning() }
                        )
                        .padding(.top, SCTheme.Spacing.sm)
                    }

                    Spacer()

                    self.contentArea(in: geometry)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 1.05).combined(with: .opacity)
                        ))
                        .animation(
                            self.userMode == .elder ? nil : SCTheme.Animation.gentle,
                            value: self.viewModel.captureState.isCapturing
                        )
                        .animation(
                            self.userMode == .elder ? nil : SCTheme.Animation.gentle,
                            value: self.viewModel.capturedScreenshot?.id
                        )

                    Spacer()

                    self.controlBar(in: geometry)
                        .padding(.bottom, SCTheme.Spacing.lg)
                }
                .padding(.horizontal, self.metrics.defaultPadding)
            }
        }
        .navigationTitle("capture.title")
        .toolbar {
            ToolbarItemGroup {
                if self.viewModel.capturedScreenshot != nil {
                    Button {
                        self.showExportSheet = true
                    } label: {
                        Label("export.title", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        withAnimation(SCTheme.Animation.spring) {
                            self.viewModel.reset()
                        }
                    } label: {
                        Label("capture.new", systemImage: "plus")
                    }
                }
            }
        }
        .alert("permission.title", isPresented: self.$showPermissionAlert) {
            Button("permission.ok") {}
        } message: {
            Text("permission.message")
        }
        .sheet(isPresented: self.$showExportSheet) {
            if let screenshot = viewModel.capturedScreenshot {
                ExportSheet(screenshot: screenshot, viewModel: self.viewModel)
            }
        }
        .task {
            self.viewModel.bind(to: self.appState)
            let hasPermission = await viewModel.requestPermission()
            if !hasPermission {
                self.showPermissionAlert = true
            }
        }
        .onChange(of: self.viewModel.capturedScreenshot?.id) { _, _ in
            if let screenshot = viewModel.capturedScreenshot {
                self.appState.addScreenshot(screenshot)
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
            self.resultSection(screenshot, in: geometry)
        } else if let preview = viewModel.currentPreview {
            self.previewSection(preview, in: geometry)
        } else {
            self.idleSection
        }
    }

    // MARK: - Idle State

    private var idleSection: some View {
        VStack(spacing: SCTheme.Spacing.xl) {
            EmptyStateView(
                systemImage: "camera.viewfinder",
                title: String(localized: "capture.ready"),
                description: self.platformDescription
            )

            #if os(macOS)
            self.macOSInstructions
            #else
            self.iOSInstructions
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
                    .frame(maxWidth: min(geometry.size.width * 0.7, self.metrics.capturePreviewMaxWidth))
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
                    .frame(maxWidth: min(geometry.size.width * 0.7, self.metrics.capturePreviewMaxWidth))
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
                    .accessibilityLabel(String(localized: "capture.complete"))
                    .accessibilityHint("\(screenshot.image.width)×\(screenshot.image.height)")
            }
            .frame(maxHeight: geometry.size.height * 0.5)

            HStack(spacing: SCTheme.Spacing.lg) {
                self.metadataBadge(icon: "ruler", value: "\(screenshot.image.width)×\(screenshot.image.height)")
                self.metadataBadge(icon: "square.stack.3d.up", value: "\(screenshot.metadata.frameCount)")
                self.metadataBadge(icon: "clock", value: String(format: "%.1fs", screenshot.metadata.durationSeconds))
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

    private func controlBar(in _: GeometryProxy) -> some View {
        VStack(spacing: SCTheme.Spacing.md) {
            FloatingActionBar {
                HStack(spacing: SCTheme.Spacing.xl) {
                    if self.viewModel.isCapturing {
                        Button {
                            self.viewModel.cancelCapture()
                        } label: {
                            if self.userMode == .elder {
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

                        self.adaptiveCaptureButton(isCapturing: true) {
                            Task { await self.viewModel.stopCapture() }
                        }
                    } else if self.viewModel.capturedScreenshot == nil {
                        self.adaptiveCaptureButton(isCapturing: false) {
                            Task { await self.viewModel.startCapture(region: self.selectedRegion) }
                        }
                    }
                }
            }
            .animation(
                self.userMode == .elder ? .easeInOut(duration: 0.2) : SCTheme.Animation.spring,
                value: self.viewModel.isCapturing
            )

            self.statusIndicator
        }
    }

    @ViewBuilder
    private func adaptiveCaptureButton(isCapturing: Bool, action: @escaping () -> Void) -> some View {
        if self.userMode == .elder {
            ElderCaptureButton(isCapturing: isCapturing, action: action)
        } else {
            CaptureButton(isCapturing: isCapturing, action: action)
        }
    }

    // MARK: - Status

    private var statusIndicator: some View {
        Group {
            switch self.viewModel.captureState {
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
            case .failed:
                StatusPill(String(localized: "error.capture.recording"), color: SCTheme.Colors.destructive)
            }
        }
        .transition(self.shouldReduceMotion ? .identity : .opacity)
        .animation(
            self.shouldReduceMotion ? nil : SCTheme.Animation.standard,
            value: self.viewModel.captureState.statusKey
        )
    }
}
