import Foundation
import OSLog

@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "analytics")
    private let eventsFileURL: URL
    private let encoder = JSONEncoder()

    private init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        eventsFileURL = documents.appendingPathComponent("analytics_events.jsonl")
        encoder.dateEncodingStrategy = .iso8601
    }

    func track(_ event: AnalyticsEvent) {
        let entry = EventEntry(
            event: event.name,
            properties: event.properties,
            timestamp: Date(),
            deviceInfo: DeviceInfo.current
        )

        logger.info("📊 Event: \(event.name)")

        if let data = try? encoder.encode(entry),
           let line = String(data: data, encoding: .utf8) {
            appendLine(line)
        }
    }

    private func appendLine(_ line: String) {
        let lineData = (line + "\n").data(using: .utf8) ?? Data()

        if FileManager.default.fileExists(atPath: eventsFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: eventsFileURL) {
                handle.seekToEndOfFile()
                handle.write(lineData)
                handle.closeFile()
            }
        } else {
            try? lineData.write(to: eventsFileURL, options: .atomic)
        }
    }
}

// MARK: - Event Entry

private struct EventEntry: Codable {
    let event: String
    let properties: [String: String]
    let timestamp: Date
    let deviceInfo: DeviceInfo
}

// MARK: - Analytics Events

enum AnalyticsEvent {
    case captureStarted(method: String)
    case captureCompleted(frames: Int, duration: TimeInterval)
    case captureFailed(error: String)
    case captureCancelled

    case stitchStarted(frames: Int)
    case stitchCompleted(frames: Int, duration: TimeInterval)
    case stitchFailed(error: String)

    case exportSaved(format: String)
    case exportShared(format: String)

    case ocrPerformed(characterCount: Int)
    case ocrFailed(error: String)

    case autoScrollStarted
    case autoScrollCompleted(scrollDistance: CGFloat)

    case iCloudSyncStarted
    case iCloudSyncCompleted(itemCount: Int)
    case iCloudSyncFailed(error: String)

    case crashDetected(name: String, reason: String)

    case appLaunched
    case screenViewed(name: String)
    case proUpgradeTapped
    case purchaseCompleted(productId: String)

    var name: String {
        switch self {
        case .captureStarted: "capture_started"
        case .captureCompleted: "capture_completed"
        case .captureFailed: "capture_failed"
        case .captureCancelled: "capture_cancelled"
        case .stitchStarted: "stitch_started"
        case .stitchCompleted: "stitch_completed"
        case .stitchFailed: "stitch_failed"
        case .exportSaved: "export_saved"
        case .exportShared: "export_shared"
        case .ocrPerformed: "ocr_performed"
        case .ocrFailed: "ocr_failed"
        case .autoScrollStarted: "auto_scroll_started"
        case .autoScrollCompleted: "auto_scroll_completed"
        case .iCloudSyncStarted: "icloud_sync_started"
        case .iCloudSyncCompleted: "icloud_sync_completed"
        case .iCloudSyncFailed: "icloud_sync_failed"
        case .crashDetected: "crash_detected"
        case .appLaunched: "app_launched"
        case .screenViewed: "screen_viewed"
        case .proUpgradeTapped: "pro_upgrade_tapped"
        case .purchaseCompleted: "purchase_completed"
        }
    }

    var properties: [String: String] {
        switch self {
        case .captureStarted(let method):
            ["method": method]
        case .captureCompleted(let frames, let duration):
            ["frames": "\(frames)", "duration": String(format: "%.2f", duration)]
        case .captureFailed(let error):
            ["error": error]
        case .captureCancelled:
            [:]
        case .stitchStarted(let frames):
            ["frames": "\(frames)"]
        case .stitchCompleted(let frames, let duration):
            ["frames": "\(frames)", "duration": String(format: "%.2f", duration)]
        case .stitchFailed(let error):
            ["error": error]
        case .exportSaved(let format):
            ["format": format]
        case .exportShared(let format):
            ["format": format]
        case .ocrPerformed(let count):
            ["character_count": "\(count)"]
        case .ocrFailed(let error):
            ["error": error]
        case .autoScrollStarted:
            [:]
        case .autoScrollCompleted(let distance):
            ["scroll_distance": String(format: "%.0f", distance)]
        case .iCloudSyncStarted:
            [:]
        case .iCloudSyncCompleted(let count):
            ["item_count": "\(count)"]
        case .iCloudSyncFailed(let error):
            ["error": error]
        case .crashDetected(let name, let reason):
            ["name": name, "reason": reason]
        case .appLaunched:
            [:]
        case .screenViewed(let name):
            ["screen": name]
        case .proUpgradeTapped:
            [:]
        case .purchaseCompleted(let productId):
            ["product_id": productId]
        }
    }
}
