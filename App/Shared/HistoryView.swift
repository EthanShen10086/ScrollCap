import DesignSystem
import SharedModels
import SwiftUI

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedScreenshotID: UUID?

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 280), spacing: SCTheme.Spacing.md),
    ]

    var body: some View {
        ZStack {
            BrandBackground()

            Group {
                if self.appState.screenshots.isEmpty {
                    EmptyStateView(
                        systemImage: "photo.on.rectangle.angled",
                        title: String(localized: "history.empty"),
                        description: String(localized: "history.empty.desc")
                    )
                } else {
                    self.screenshotGrid
                }
            }
        }
        .navigationTitle("nav.history")
        .navigationDestination(item: self.$selectedScreenshotID) { id in
            if let screenshot = appState.screenshots.first(where: { $0.id == id }) {
                ScreenshotDetailView(screenshot: screenshot)
            }
        }
    }

    private var screenshotGrid: some View {
        ScrollView {
            LazyVGrid(columns: self.columns, spacing: SCTheme.Spacing.md) {
                ForEach(self.appState.screenshots) { screenshot in
                    HistoryScreenshotCard(screenshot: screenshot) {
                        self.appState.selectedScreenshot = screenshot
                        self.selectedScreenshotID = screenshot.id
                    }
                    .contextMenu {
                        Button("detail.delete", role: .destructive) {
                            withAnimation(SCTheme.Animation.spring) {
                                self.appState.removeScreenshot(screenshot)
                            }
                            AnalyticsManager.shared.track(.screenshotDeleted)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.userMode) private var userMode

    private var shouldReduceMotion: Bool {
        self.reduceMotion || self.userMode == .elder
    }

    var body: some View {
        Button(action: self.action) {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Image(decorative: self.screenshot.image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.screenshot.createdAt, style: .date)
                        .font(SCTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: SCTheme.Spacing.sm) {
                        Text("\(self.screenshot.image.width)×\(self.screenshot.image.height)")
                            .font(SCTheme.Typography.monoCaption)
                        Text("·")
                        Text("capture.frames \(self.screenshot.metadata.frameCount)")
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
                    .fill(self.colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                            .stroke(Color.white.opacity(self.colorScheme == .dark ? 0.08 : 0.3), lineWidth: 0.5)
                    )
                    .shadow(
                        color: self.colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
                        radius: self.isHovered ? 16 : 8,
                        y: self.isHovered ? 8 : 4
                    )
            }
            .scaleEffect(self.shouldReduceMotion ? 1.0 : (self.isHovered ? 1.03 : 1.0))
            .animation(self.shouldReduceMotion ? nil : SCTheme.Animation.gentle, value: self.isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text("a11y.screenshot.label \(self.screenshot.createdAt.formatted(date: .abbreviated, time: .shortened))")
        )
        .accessibilityHint(
            Text(
                "a11y.screenshot.hint \(self.screenshot.metadata.frameCount) \(self.screenshot.image.width) \(self.screenshot.image.height)"
            )
        )
        .accessibilityAddTraits(.isButton)
    }
}
