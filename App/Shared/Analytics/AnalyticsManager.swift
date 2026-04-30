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
        self.eventsFileURL = documents.appendingPathComponent("analytics_events.jsonl")
        self.encoder.dateEncodingStrategy = .iso8601
    }

    func track(_ event: AnalyticsEvent) {
        let entry = EventEntry(
            event: event.name,
            properties: event.properties,
            timestamp: Date(),
            deviceInfo: DeviceInfo.current
        )

        self.logger.info("📊 Event: \(event.name)")

        if let data = try? encoder.encode(entry),
           let line = String(data: data, encoding: .utf8) {
            self.appendLine(line)
        }
    }

    private func appendLine(_ line: String) {
        let lineData = (line + "\n").data(using: .utf8) ?? Data()

        if FileManager.default.fileExists(atPath: self.eventsFileURL.path) {
            if let handle = try? FileHandle(forWritingTo: eventsFileURL) {
                handle.seekToEndOfFile()
                handle.write(lineData)
                handle.closeFile()
            }
        } else {
            try? lineData.write(to: self.eventsFileURL, options: .atomic)
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
    case purchaseFailed(productId: String, error: String)
    case purchaseCancelled(productId: String)
    case restoreCompleted(count: Int)
    case restoreFailed(error: String)

    case error(domain: String, code: String)

    case entitlementGranted(source: String)
    case entitlementRevoked

    case settingsChanged(key: String, value: String)
    case screenshotDeleted
    case screenshotOpened

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
        case .purchaseFailed: "purchase_failed"
        case .purchaseCancelled: "purchase_cancelled"
        case .restoreCompleted: "restore_completed"
        case .restoreFailed: "restore_failed"
        case .error: "error"
        case .entitlementGranted: "entitlement_granted"
        case .entitlementRevoked: "entitlement_revoked"
        case .settingsChanged: "settings_changed"
        case .screenshotDeleted: "screenshot_deleted"
        case .screenshotOpened: "screenshot_opened"
        }
    }

    var properties: [String: String] {
        switch self {
        case let .captureStarted(method):
            ["method": method]
        case let .captureCompleted(frames, duration):
            ["frames": "\(frames)", "duration": String(format: "%.2f", duration)]
        case let .captureFailed(error):
            ["error": error]
        case .captureCancelled:
            [:]
        case let .stitchStarted(frames):
            ["frames": "\(frames)"]
        case let .stitchCompleted(frames, duration):
            ["frames": "\(frames)", "duration": String(format: "%.2f", duration)]
        case let .stitchFailed(error):
            ["error": error]
        case let .exportSaved(format):
            ["format": format]
        case let .exportShared(format):
            ["format": format]
        case let .ocrPerformed(count):
            ["character_count": "\(count)"]
        case let .ocrFailed(error):
            ["error": error]
        case .autoScrollStarted:
            [:]
        case let .autoScrollCompleted(distance):
            ["scroll_distance": String(format: "%.0f", distance)]
        case .iCloudSyncStarted:
            [:]
        case let .iCloudSyncCompleted(count):
            ["item_count": "\(count)"]
        case let .iCloudSyncFailed(error):
            ["error": error]
        case let .crashDetected(name, reason):
            ["name": name, "reason": reason]
        case .appLaunched:
            [:]
        case let .screenViewed(name):
            ["screen": name]
        case .proUpgradeTapped:
            [:]
        case let .purchaseCompleted(productId):
            ["product_id": productId]
        case let .purchaseFailed(productId, error):
            ["product_id": productId, "error": error]
        case let .purchaseCancelled(productId):
            ["product_id": productId]
        case let .restoreCompleted(count):
            ["count": "\(count)"]
        case let .restoreFailed(error):
            ["error": error]
        case let .error(domain, code):
            ["domain": domain, "code": code]
        case let .entitlementGranted(source):
            ["source": source]
        case .entitlementRevoked:
            [:]
        case let .settingsChanged(key, value):
            ["key": key, "value": value]
        case .screenshotDeleted:
            [:]
        case .screenshotOpened:
            [:]
        }
    }
}
