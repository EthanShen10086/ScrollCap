import DesignSystem
import SharedModels
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 280), spacing: SCTheme.Spacing.md),
    ]

    var body: some View {
        ZStack {
            BrandBackground()

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
        }
        .navigationTitle("nav.history")
    }

    private var screenshotGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: SCTheme.Spacing.md) {
                ForEach(appState.screenshots) { screenshot in
                    HistoryScreenshotCard(screenshot: screenshot) {
                        appState.selectedScreenshot = screenshot
                    }
                    .contextMenu {
                        Button("detail.delete", role: .destructive) {
                            withAnimation(SCTheme.Animation.spring) {
                                appState.removeScreenshot(screenshot)
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(SCTheme.Spacing.md)
        }
    }
}

// MARK: - History Screenshot Card

struct HistoryScreenshotCard: View {
    let screenshot: Screenshot
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Image(decorative: screenshot.image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(screenshot.createdAt, style: .date)
                        .font(SCTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: SCTheme.Spacing.sm) {
                        Text("\(screenshot.image.width)×\(screenshot.image.height)")
                            .font(SCTheme.Typography.monoCaption)
                        Text("·")
                        Text("capture.frames \(screenshot.metadata.frameCount)")
                            .font(SCTheme.Typography.monoCaption)
                    }
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                .padding(.horizontal, 4)
            }
            .padding(SCTheme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.5)
                    )
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
                        radius: isHovered ? 16 : 8,
                        y: isHovered ? 8 : 4
                    )
            }
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(SCTheme.Animation.gentle, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "detail.title"))
        .accessibilityHint(
            "\(screenshot.metadata.frameCount) frames, \(screenshot.image.width)×\(screenshot.image.height)"
        )
        .accessibilityAddTraits(.isButton)
    }
}
