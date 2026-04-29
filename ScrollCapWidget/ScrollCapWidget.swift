import AppIntents
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
        let defaults = UserDefaults(suiteName: "group.com.ethanshen.scrollcap")
        return defaults?.integer(forKey: "captureCount") ?? 0
    }
}

// MARK: - Entry

struct ScrollCapEntry: TimelineEntry {
    let date: Date
    let captureCount: Int
}

// MARK: - Quick Capture Intent

struct QuickCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Capture"
    static let description = IntentDescription("Start a new scrolling screenshot capture")
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
        switch family {
        case .systemSmall:
            smallWidget
        case .accessoryRectangular:
            lockScreenWidget
        case .accessoryCircular:
            circularWidget
        default:
            smallWidget
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

            Text("ScrollCap")
                .font(.system(.caption, design: .rounded).weight(.semibold))

            if entry.captureCount > 0 {
                Text("\(entry.captureCount) captures")
                    .font(.system(.caption2))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(intent: QuickCaptureIntent()) {
                Text("Capture")
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
                Text("ScrollCap")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                Text("Quick Capture")
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
        StaticConfiguration(kind: kind, provider: ScrollCapProvider()) { entry in
            ScrollCapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ScrollCap")
        .description("Quick access to scrolling screenshot capture.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryCircular])
    }
}

// MARK: - Widget Bundle

@main
struct ScrollCapWidgetBundle: WidgetBundle {
    var body: some Widget {
        ScrollCapQuickCaptureWidget()
    }
}
