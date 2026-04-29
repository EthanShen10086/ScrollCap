#if os(macOS)
import SwiftUI
import DesignSystem
import SharedModels

struct MacCaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var isSelectingRegion = false
    @State private var selectedRegion: CaptureRegion?

    var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            if isSelectingRegion {
                regionSelectionPrompt
            } else if let region = selectedRegion {
                regionInfoCard(region)
            }

            captureActions
        }
        .padding()
    }

    private var regionSelectionPrompt: some View {
        GlassCard {
            VStack(spacing: SCTheme.Spacing.md) {
                Image(systemName: "rectangle.dashed")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("Drag to select capture area")
                    .font(SCTheme.Typography.headline)

                Text("The selected region will be captured during scrolling")
                    .font(SCTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func regionInfoCard(_ region: CaptureRegion) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
                    Text("Selected Region")
                        .font(SCTheme.Typography.headline)

                    Text("\(Int(region.size.width))×\(Int(region.size.height)) points")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Change") {
                    isSelectingRegion = true
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var captureActions: some View {
        HStack(spacing: SCTheme.Spacing.md) {
            Button {
                isSelectingRegion = true
            } label: {
                Label("Select Region", systemImage: "rectangle.dashed")
            }
            .buttonStyle(.bordered)

            if selectedRegion != nil {
                Button {
                    startMacCapture()
                } label: {
                    Label("Start Capture", systemImage: "record.circle")
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(SCTheme.Colors.captureReady)
            }
        }
    }

    private func startMacCapture() {
        appState.captureState = .preparing
    }
}
#endif
