import SharedModels
import SwiftUI
#if os(macOS)
import CaptureKitMac
#elseif os(iOS)
import CaptureKitIOS
#endif
import CaptureKit
import os.signpost

@Observable
@MainActor
final class CaptureViewModel {
    private(set) var captureState: CaptureState = .idle
    private(set) var currentPreview: CGImage?
    private(set) var capturedScreenshot: Screenshot?
    private(set) var errorMessage: String?

    private let captureService: any CaptureService
    private var captureStartTime: CFAbsoluteTime = 0
    private var captureSignpostID: OSSignpostID?

    var isCapturing: Bool {
        self.captureState.isActive
    }

    init() {
        #if os(macOS)
        self.captureService = ScreenCaptureService()
        #elseif os(iOS)
        self.captureService = ReplayKitCaptureService()
        #endif

        self.setupCallbacks()
    }

    private func setupCallbacks() {
        self.captureService.onStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.captureState = state
                self?.syncToAppState()
            }
        }

        self.captureService.onPreviewUpdated = { [weak self] image in
            Task { @MainActor in
                self?.currentPreview = image
            }
        }
    }

    private func syncToAppState() {
        self.appStateRef?.captureState = self.captureState
    }

    private weak var appStateRef: AppState?

    func bind(to appState: AppState) {
        self.appStateRef = appState
    }

    // MARK: - Public Actions

    func requestPermission() async -> Bool {
        await self.captureService.requestPermission()
    }

    func prepare() async {
        do {
            try await self.captureService.prepare()
        } catch {
            let msg = self.localizedErrorMessage(error)
            self.captureState = .failed(message: msg)
            self.errorMessage = msg
            SCLogger.capture.failed("prepare", error: error)
            AnalyticsManager.shared.track(.captureFailed(error: "prepare: \(error.localizedDescription)"))
            ErrorPresenter.shared.present(error)
        }
    }

    func startCapture(region: CaptureRegion? = nil) async {
        self.errorMessage = nil
        self.captureStartTime = CFAbsoluteTimeGetCurrent()

        let method: String
        #if os(macOS)
        method = "ScreenCaptureKit"
        #else
        method = "ReplayKit"
        #endif
        self.captureSignpostID = PerformanceMonitor.beginCapture()
        SCLogger.capture.started("region: \(region.map { "\($0)" } ?? "full")")
        AnalyticsManager.shared.track(.captureStarted(method: method))

        do {
            try await self.captureService.startCapture(region: region)
            HapticManager.captureStarted()
        } catch {
            let msg = self.localizedErrorMessage(error)
            self.captureState = .failed(message: msg)
            self.errorMessage = msg
            SCLogger.capture.failed("startCapture", error: error)
            AnalyticsManager.shared.track(.captureFailed(error: error.localizedDescription))
            ErrorPresenter.shared.present(error)
            HapticManager.captureError()
        }
    }

    func stopCapture() async {
        do {
            if let screenshot = try await captureService.stopCapture() {
                self.capturedScreenshot = screenshot
                let duration = CFAbsoluteTimeGetCurrent() - self.captureStartTime
                if let sid = captureSignpostID {
                    PerformanceMonitor.endCapture(sid, frames: screenshot.metadata.frameCount)
                }
                PerformanceMonitor.reportMemoryUsage()
                SCLogger.capture.completed("frames: \(screenshot.metadata.frameCount)", duration: duration)
                AnalyticsManager.shared.track(.captureCompleted(
                    frames: screenshot.metadata.frameCount,
                    duration: duration
                ))
                HapticManager.captureStopped()
            } else {
                let duration = CFAbsoluteTimeGetCurrent() - self.captureStartTime
                SCLogger.capture.failed("stopCapture returned nil (stitch failed)", error: nil)
                AnalyticsManager.shared.track(.stitchFailed(error: "returned_nil"))
                AnalyticsManager.shared
                    .track(.captureFailed(error: "stitch_returned_nil_after_\(String(format: "%.1f", duration))s"))
            }
        } catch {
            let msg = self.localizedErrorMessage(error)
            self.captureState = .failed(message: msg)
            self.errorMessage = msg
            SCLogger.capture.failed("stopCapture", error: error)
            AnalyticsManager.shared.track(.captureFailed(error: error.localizedDescription))
            ErrorPresenter.shared.present(error)
            HapticManager.captureError()
        }
    }

    func cancelCapture() {
        self.captureService.cancelCapture()
        self.currentPreview = nil
        self.captureState = .idle
        self.syncToAppState()
        SCLogger.capture.info("Capture cancelled by user")
        AnalyticsManager.shared.track(.captureCancelled)
    }

    func reset() {
        self.capturedScreenshot = nil
        self.currentPreview = nil
        self.errorMessage = nil
        self.captureState = .idle
        self.syncToAppState()
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        if let scError = error as? SCError {
            return scError.userMessage
        }
        return String(localized: "error.capture.recording")
    }

    // MARK: - Export

    func exportScreenshot(options: ExportOptions, to url: URL) async throws {
        guard let screenshot = capturedScreenshot else { return }
        let exportService = ExportService()
        try await exportService.export(image: screenshot.image, options: options, to: url)
    }

    func exportToData(options: ExportOptions) async throws -> Data? {
        guard let screenshot = capturedScreenshot else { return nil }
        let exportService = ExportService()
        return try await exportService.exportToData(image: screenshot.image, options: options)
    }
}
