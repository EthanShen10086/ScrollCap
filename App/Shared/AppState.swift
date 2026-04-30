import DesignSystem
import OSLog
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
        Int(Date().timeIntervalSince(self.sessionStartTime) / 60)
    }

    var isMinorMode: Bool {
        self.userMode == .minor
    }

    var isElderMode: Bool {
        self.userMode == .elder
    }

    var shouldHidePayment: Bool {
        self.userMode == .minor
    }

    func checkUsageTime() {
        guard self.userMode == .minor, !self.usageWarningDismissed else { return }
        if self.sessionMinutesUsed >= self.minorUsageLimitMinutes {
            self.showUsageWarning = true
        }
    }

    func dismissUsageWarning() {
        self.showUsageWarning = false
        self.usageWarningDismissed = true
    }

    func resetSession() {
        self.sessionStartTime = Date()
        self.usageWarningDismissed = false
        self.showUsageWarning = false
    }

    // MARK: - Core

    var isCapturing: Bool {
        self.captureState.isActive
    }

    private static let appGroupID = AppConstants.appGroupID

    func addScreenshot(_ screenshot: Screenshot) {
        self.screenshots.insert(screenshot, at: 0)
        self.selectedScreenshot = screenshot
        self.updateWidgetData()
        self.syncToCloudIfEnabled(screenshot)
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        defaults?.set(self.screenshots.count, forKey: AppConstants.UserDefaultsKeys.captureCount)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func syncToCloudIfEnabled(_ screenshot: Screenshot) {
        guard self.iCloudSyncEnabled, ICloudSyncManager.shared.isAvailable else { return }
        Task.detached(priority: .utility) {
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
        self.screenshots.removeAll { $0.id == screenshot.id }
        if self.selectedScreenshot?.id == screenshot.id {
            self.selectedScreenshot = self.screenshots.first
        }
        AnalyticsManager.shared.track(.screenshotDeleted)
    }

    func handleMemoryWarning() {
        self.currentPreview = nil
        SCLogger.app.warning("Memory warning: cleared preview cache")
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
