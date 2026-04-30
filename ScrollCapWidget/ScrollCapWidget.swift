import ActivityKit
import AppIntents
import SharedModels
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct ScrollCapProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScrollCapEntry {
        ScrollCapEntry(date: Date(), captureCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScrollCapEntry) -> Void) {
        let entry = ScrollCapEntry(date: Date(), captureCount: getCaptureCount())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScrollCapEntry>) -> Void) {
        let entry = ScrollCapEntry(date: Date(), captureCount: getCaptureCount())
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
        completion(timeline)
    }

    private func getCaptureCount() -> Int {
        let defaults = UserDefaults(suiteName: AppConstants.appGroupID)
        return defaults?.integer(forKey: AppConstants.UserDefaultsKeys.captureCount) ?? 0
    }
}

// MARK: - Entry

struct ScrollCapEntry: TimelineEntry {
    let date: Date
    let captureCount: Int
}

// MARK: - Quick Capture Intent

struct QuickCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "widget.quickCapture"
    static let description = IntentDescription("widget.configDesc")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// MARK: - Widget Views

struct ScrollCapWidgetEntryView: View {
    var entry: ScrollCapProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch self.family {
        case .systemSmall:
            self.smallWidget
        case .accessoryRectangular:
            self.lockScreenWidget
        case .accessoryCircular:
            self.circularWidget
        default:
            self.smallWidget
        }
    }

    private var smallWidget: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.0, green: 0.47, blue: 0.98), Color(red: 0.42, green: 0.36, blue: 0.91)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("widget.name")
                .font(.system(.caption, design: .rounded).weight(.semibold))

            if self.entry.captureCount > 0 {
                Text("widget.captures \(self.entry.captureCount)")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(intent: QuickCaptureIntent()) {
                Text("widget.capture")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.47, blue: 0.98),
                                Color(red: 0.42, green: 0.36, blue: 0.91),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var lockScreenWidget: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 20, weight: .medium))

            VStack(alignment: .leading, spacing: 2) {
                Text("widget.name")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Text("widget.quickCapture")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "scrollcap://capture"))
    }

    private var circularWidget: some View {
        Image(systemName: "camera.viewfinder")
            .font(.system(size: 20, weight: .medium))
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "scrollcap://capture"))
    }
}

// MARK: - Widget Configuration

struct ScrollCapQuickCaptureWidget: Widget {
    let kind: String = "ScrollCapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: self.kind, provider: ScrollCapProvider()) { entry in
            ScrollCapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("widget.configName")
        .description("widget.configDesc")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Widget Bundle

// MARK: - Live Activity

struct CaptureActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CaptureActivityAttributes.self) { context in
            CaptureActivityLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.capturedFrames)", systemImage: "photo.stack")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(String(localized: "liveactivity.elapsed \(context.state.elapsedSeconds)"))
                        .font(.system(.headline, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.phase.displayText)
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.estimatedHeight > 0 {
                        HStack {
                            Image(systemName: "arrow.up.and.down")
                            Text(String(localized: "liveactivity.estimatedHeight \(context.state.estimatedHeight)"))
                                .font(.system(.caption, design: .monospaced))
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                Text("\(context.state.capturedFrames)")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.blue)
            } minimal: {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(.blue)
            }
        }
    }
}

struct CaptureActivityLockScreenView: View {
    let state: CaptureActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.state.phase.displayText)
                    .font(.system(.headline, design: .rounded))

                HStack(spacing: 12) {
                    Label(
                        String(localized: "liveactivity.frames \(self.state.capturedFrames)"),
                        systemImage: "photo.stack"
                    )
                    Label(String(localized: "liveactivity.elapsed \(self.state.elapsedSeconds)"), systemImage: "clock")
                    if self.state.estimatedHeight > 0 {
                        Label(
                            String(localized: "liveactivity.estimatedHeight \(self.state.estimatedHeight)"),
                            systemImage: "arrow.up.and.down"
                        )
                    }
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.75))
    }
}

extension CaptureActivityAttributes.CapturePhase {
    var displayText: String {
        switch self {
        case .preparing: String(localized: "status.preparing")
        case .capturing: String(localized: "status.recording")
        case .stitching: String(localized: "status.stitching")
        case .completed: String(localized: "status.completed")
        case .failed: String(localized: "status.failed")
        }
    }
}

@main
struct ScrollCapWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScrollCapQuickCaptureWidget()
        CaptureActivityWidget()
    }
}
