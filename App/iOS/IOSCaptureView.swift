#if os(iOS)
import SwiftUI
import ReplayKit
import DesignSystem
import SharedModels

struct IOSCaptureView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            Text("Screen Broadcast")
                .font(SCTheme.Typography.title)

            Text("Use the system broadcast picker to start recording. ScrollCap will capture frames from any app you use.")
                .font(SCTheme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            BroadcastPickerRepresentable()
                .frame(width: 60, height: 60)
                .padding()
                .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.lg)

            if appState.isCapturing {
                captureProgressView
            }
        }
        .padding()
    }

    private var captureProgressView: some View {
        GlassCard {
            VStack(spacing: SCTheme.Spacing.sm) {
                HStack {
                    Circle()
                        .fill(SCTheme.Colors.captureActive)
                        .frame(width: 10, height: 10)
                        .scaleEffect(1.2)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: true)

                    Text("Recording...")
                        .font(SCTheme.Typography.headline)
                        .foregroundStyle(SCTheme.Colors.captureActive)
                }

                if case .capturing(let progress) = appState.captureState {
                    Text("\(progress.capturedFrames) frames captured")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.secondary)

                    Text(String(format: "%.0f px estimated height", progress.estimatedHeight))
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
#endif
