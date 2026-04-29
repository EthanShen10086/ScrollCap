import SwiftUI
import SharedModels

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

    var isCapturing: Bool {
        captureState.isActive
    }

    func addScreenshot(_ screenshot: Screenshot) {
        screenshots.insert(screenshot, at: 0)
        selectedScreenshot = screenshot
    }

    func removeScreenshot(_ screenshot: Screenshot) {
        screenshots.removeAll { $0.id == screenshot.id }
        if selectedScreenshot?.id == screenshot.id {
            selectedScreenshot = screenshots.first
        }
    }
}

enum AppDestination: Hashable, Identifiable {
    case capture
    case history
    case settings

    var id: Self { self }

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
