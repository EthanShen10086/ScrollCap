import SwiftUI
import DesignSystem
import SharedModels

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var showPermissionAlert = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient

                VStack(spacing: SCTheme.Spacing.xl) {
                    if let preview = appState.currentPreview {
                        previewSection(preview, in: geometry)
                    } else {
                        idleSection
                    }

                    captureControls
                    statusBar
                }
                .padding(SCTheme.Spacing.lg)
            }
        }
        .navigationTitle("Capture")
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("OK") {}
        } message: {
            Text("ScrollCap needs screen recording permission to capture scrolling content.")
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Idle State

    private var idleSection: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            EmptyStateView(
                systemImage: "scroll",
                title: "Ready to Capture",
                description: platformDescription
            )
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

    // MARK: - Preview

    private func previewSection(_ image: CGImage, in geometry: GeometryProxy) -> some View {
        ScrollView {
            Image(decorative: image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: min(geometry.size.width * 0.8, 600))
                .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.lg)
        }
        .frame(maxHeight: geometry.size.height * 0.6)
    }

    // MARK: - Controls

    private var captureControls: some View {
        HStack(spacing: SCTheme.Spacing.lg) {
            if appState.isCapturing {
                CaptureButton(isCapturing: true) {
                    stopCapture()
                }

                Button("Cancel", role: .destructive) {
                    cancelCapture()
                }
                .buttonStyle(.bordered)
            } else {
                CaptureButton(isCapturing: false) {
                    startCapture()
                }
            }
        }
        .padding()
        .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.xl)
    }

    // MARK: - Status Bar

    @ViewBuilder
    private var statusBar: some View {
        switch appState.captureState {
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

    // MARK: - Actions

    private func startCapture() {
        // Platform-specific capture start handled via CaptureService
        appState.captureState = .preparing
    }

    private func stopCapture() {
        appState.captureState = .stitching
    }

    private func cancelCapture() {
        appState.captureState = .idle
        appState.currentPreview = nil
    }
}
