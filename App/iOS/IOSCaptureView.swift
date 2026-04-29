#if os(iOS)
import SwiftUI
import ReplayKit
import DesignSystem
import SharedModels

struct IOSCaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var showBroadcastPicker = false

    var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            instructionCard

            if appState.isCapturing {
                captureProgressCard
            }
        }
        .padding()
    }

    private var instructionCard: some View {
        GlassCard {
            VStack(spacing: SCTheme.Spacing.md) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)

                Text("How to Capture")
                    .font(SCTheme.Typography.title)

                VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                    InstructionRow(number: 1, text: "Tap the capture button below")
                    InstructionRow(number: 2, text: "Switch to the app you want to capture")
                    InstructionRow(number: 3, text: "Scroll slowly through the content")
                    InstructionRow(number: 4, text: "Return here and tap stop")
                }
            }
        }
    }

    private var captureProgressCard: some View {
        GlassCard {
            VStack(spacing: SCTheme.Spacing.sm) {
                HStack {
                    Circle()
                        .fill(SCTheme.Colors.captureActive)
                        .frame(width: 10, height: 10)
                        .scaleEffect(appState.isCapturing ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(), value: appState.isCapturing)

                    Text("Recording...")
                        .font(SCTheme.Typography.headline)
                        .foregroundStyle(SCTheme.Colors.captureActive)
                }

                if case .capturing(let progress) = appState.captureState {
                    Text("\(progress.capturedFrames) frames captured")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

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
