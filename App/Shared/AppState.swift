import DesignSystem
import SharedModels
import SwiftUI
import WidgetKit

@Observable
@MainActor
final class AppState {
    var captureState: CaptureState = .idle
    var currentPreview: CGImage?
    var screenshots: [Screenshot] = []
    var selectedScreenshot: Screenshot?
    var selectedDestination: AppDestination? = .capture

    var exportFormat: ExportFormat = .png
    var exportQuality: Double = 0.9
    var autoScrollEnabled: Bool = false
    var iCloudSyncEnabled: Bool = false

    // MARK: - User Mode

    var userMode: UserMode = .standard
    var minorUsageLimitMinutes: Int = 40
    private(set) var sessionStartTime = Date()
    private(set) var showUsageWarning = false
    private var usageWarningDismissed = false

    var sessionMinutesUsed: Int {
        Int(Date().timeIntervalSince(sessionStartTime) / 60)
    }

    var isMinorMode: Bool {
        userMode == .minor
    }

    var isElderMode: Bool {
        userMode == .elder
    }

    var shouldHidePayment: Bool {
        userMode == .minor
    }

    func checkUsageTime() {
        guard userMode == .minor, !usageWarningDismissed else { return }
        if sessionMinutesUsed >= minorUsageLimitMinutes {
            showUsageWarning = true
        }
    }

    func dismissUsageWarning() {
        showUsageWarning = false
        usageWarningDismissed = true
    }

    func resetSession() {
        sessionStartTime = Date()
        usageWarningDismissed = false
        showUsageWarning = false
    }

    // MARK: - Core

    var isCapturing: Bool {
        captureState.isActive
    }

    private static let appGroupID = "group.com.scrollcap.shared"

    func addScreenshot(_ screenshot: Screenshot) {
        screenshots.insert(screenshot, at: 0)
        selectedScreenshot = screenshot
        updateWidgetData()
        syncToCloudIfEnabled(screenshot)
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        defaults?.set(screenshots.count, forKey: "captureCount")
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func syncToCloudIfEnabled(_ screenshot: Screenshot) {
        guard iCloudSyncEnabled, ICloudSyncManager.shared.isAvailable else { return }
        Task {
            guard let data = screenshot.pngData else { return }
            let record = ScreenshotSyncRecord(
                id: screenshot.id,
                filename: "\(screenshot.id.uuidString).png",
                createdAt: screenshot.createdAt,
                width: screenshot.image.width,
                height: screenshot.image.height,
                frameCount: screenshot.metadata.frameCount,
                captureMethod: screenshot.metadata.captureMethod.rawValue,
                durationSeconds: screenshot.metadata.durationSeconds
            )
            await ICloudSyncManager.shared.syncScreenshot(imageData: data, record: record)
        }
    }

    func removeScreenshot(_ screenshot: Screenshot) {
        screenshots.removeAll { $0.id == screenshot.id }
        if selectedScreenshot?.id == screenshot.id {
            selectedScreenshot = screenshots.first
        }
        AnalyticsManager.shared.track(.screenshotDeleted)
    }
}

enum AppDestination: Hashable, Identifiable {
    case capture
    case history
    case settings

    var id: Self {
        self
    }

    var title: LocalizedStringKey {
        switch self {
        case .capture: "nav.capture"
        case .history: "nav.history"
        case .settings: "nav.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .capture: "camera.viewfinder"
        case .history: "clock.arrow.circlepath"
        case .settings: "gear"
        }
    }
}
