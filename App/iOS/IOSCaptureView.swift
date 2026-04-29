#if os(iOS)
import DesignSystem
import ReplayKit
import SharedModels
import SwiftUI

struct IOSCaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var frameReader = SharedFrameReader()

    var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            Text("ios.broadcast")
                .font(SCTheme.Typography.title)

            Text("ios.broadcast.desc")
                .font(SCTheme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            BroadcastPickerRepresentable()
                .frame(width: 60, height: 60)
                .padding()
                .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.lg)

            if appState.isCapturing || frameReader.isBroadcasting {
                captureProgressView
            }
        }
        .padding()
        .onAppear { frameReader.startMonitoring() }
        .onDisappear { frameReader.stopMonitoring() }
    }

    private var captureProgressView: some View {
        GlassCard {
            VStack(spacing: SCTheme.Spacing.sm) {
                HStack {
                    Circle()
                        .fill(SCTheme.Colors.captureActive)
                        .frame(width: 10, height: 10)
                        .scaleEffect(reduceMotion ? 1.0 : 1.2)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.6).repeatForever(), value: reduceMotion)

                    Text("ios.recording")
                        .font(SCTheme.Typography.headline)
                        .foregroundStyle(SCTheme.Colors.captureActive)
                }

                let frames = frameReader.currentFrameCount
                if frames > 0 {
                    Text("ios.framesCaptured \(frames)")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.secondary)
                } else if case let .capturing(progress) = appState.captureState {
                    Text("ios.framesCaptured \(progress.capturedFrames)")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.secondary)

                    Text("ios.estimatedHeight \(String(format: "%.0f", progress.estimatedHeight))")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
#endif
