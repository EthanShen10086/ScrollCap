#if os(macOS)
import DesignSystem
import SharedModels
import SwiftUI

struct MacCaptureView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRegion: CaptureRegion?
    @State private var overlayController = OverlayWindowController()

    var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            if let region = selectedRegion {
                self.regionInfoCard(region)
            }

            self.captureActions
        }
        .padding()
    }

    private func regionInfoCard(_ region: CaptureRegion) -> some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: SCTheme.Spacing.xs) {
                    Text("mac.selectedRegion")
                        .font(SCTheme.Typography.headline)

                    HStack(spacing: SCTheme.Spacing.md) {
                        Label("\(Int(region.size.width))×\(Int(region.size.height))", systemImage: "rectangle.dashed")
                        Label("mac.pixels \(region.pixelWidth) \(region.pixelHeight)", systemImage: "square.resize")
                    }
                    .font(SCTheme.Typography.monoCaption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button("mac.change") {
                    self.showRegionSelector()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var captureActions: some View {
        HStack(spacing: SCTheme.Spacing.md) {
            Button {
                self.showRegionSelector()
            } label: {
                Label("mac.selectRegion", systemImage: "rectangle.dashed")
            }
            .buttonStyle(.bordered)
        }
    }

    private func showRegionSelector() {
        self.overlayController.showRegionSelector { region in
            self.selectedRegion = region
        }
    }
}
#endif
