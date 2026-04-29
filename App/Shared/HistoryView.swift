import SwiftUI
import DesignSystem
import SharedModels

struct HistoryView: View {
    @Environment(AppState.self) private var appState

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: SCTheme.Spacing.md)
    ]

    var body: some View {
        Group {
            if appState.screenshots.isEmpty {
                EmptyStateView(
                    systemImage: "photo.on.rectangle.angled",
                    title: String(localized: "history.empty"),
                    description: String(localized: "history.empty.desc")
                )
            } else {
                screenshotGrid
            }
        }
        .navigationTitle("nav.history")
    }

    private var screenshotGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: SCTheme.Spacing.md) {
                ForEach(appState.screenshots) { screenshot in
                    ScreenshotCard(screenshot: screenshot)
                        .onTapGesture {
                            appState.selectedScreenshot = screenshot
                        }
                        .contextMenu {
                            Button("detail.delete", role: .destructive) {
                                withAnimation(SCTheme.Animation.standard) {
                                    appState.removeScreenshot(screenshot)
                                }
                            }
                        }
                }
            }
            .padding(SCTheme.Spacing.md)
        }
    }
}

// MARK: - Screenshot Card

struct ScreenshotCard: View {
    let screenshot: Screenshot

    var body: some View {
        VStack(spacing: SCTheme.Spacing.sm) {
            Image(decorative: screenshot.image, scale: 1.0)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(screenshot.createdAt, style: .date)
                        .font(SCTheme.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text("capture.frames \(screenshot.metadata.frameCount)")
                        .font(SCTheme.Typography.monoCaption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
        }
        .padding(SCTheme.Spacing.sm)
        .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.lg)
    }
}
