#if os(macOS)
import SwiftUI
import DesignSystem
import SharedModels

struct MacCaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRegion: CaptureRegion?
    @State private var overlayController = OverlayWindowController()

    var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            if let region = selectedRegion {
                regionInfoCard(region)
            }

            captureActions
        }
        .padding()
    }

    private func regionInfoCard(_ region: CaptureRegion) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
                    Text("Selected Region")
                        .font(SCTheme.Typography.headline)

                    HStack(spacing: SCTheme.Spacing.md) {
                        Label("\(Int(region.size.width))×\(Int(region.size.height))", systemImage: "rectangle.dashed")
                        Label("\(region.pixelWidth)×\(region.pixelHeight) px", systemImage: "square.resize")
                    }
                    .font(SCTheme.Typography.monoCaption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Change") {
                    showRegionSelector()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var captureActions: some View {
        HStack(spacing: SCTheme.Spacing.md) {
            Button {
                showRegionSelector()
            } label: {
                Label("Select Region", systemImage: "rectangle.dashed")
            }
            .buttonStyle(.bordered)
        }
    }

    private func showRegionSelector() {
        overlayController.showRegionSelector { region in
            selectedRegion = region
        }
    }
}
#endif
