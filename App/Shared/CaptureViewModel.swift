import SwiftUI
import SharedModels
import StitchingEngine
import ImageEditor
#if os(macOS)
import CaptureKitMac
#elseif os(iOS)
import CaptureKitIOS
#endif
import CaptureKit

@Observable
@MainActor
final class CaptureViewModel {
    private(set) var captureState: CaptureState = .idle
    private(set) var currentPreview: CGImage?
    private(set) var liveStitchPreview: CGImage?
    private(set) var capturedScreenshot: Screenshot?
    private(set) var errorMessage: String?

    private let captureService: any CaptureService
    private var collectedFrames: [StitchFrame] = []
    private let aligner = FrameAligner()
    private let stitcher = ImageStitcher()
    private var captureStartTime: CFAbsoluteTime = 0

    var isCapturing: Bool { captureState.isActive }

    init() {
        #if os(macOS)
        self.captureService = ScreenCaptureService()
        #elseif os(iOS)
        self.captureService = ReplayKitCaptureService()
        #endif

        setupCallbacks()
    }

    private func setupCallbacks() {
        captureService.onStateChanged = { [weak self] state in
            Task { @MainActor in
                self?.captureState = state
            }
        }

        captureService.onPreviewUpdated = { [weak self] image in
            Task { @MainActor in
                self?.currentPreview = image
            }
        }
    }

    // MARK: - Public Actions

    func requestPermission() async -> Bool {
        await captureService.requestPermission()
    }

    func prepare() async {
        do {
            try await captureService.prepare()
        } catch {
            captureState = .failed(message: error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func startCapture(region: CaptureRegion? = nil) async {
        errorMessage = nil
        collectedFrames.removeAll()
        await aligner.reset()
        captureStartTime = CFAbsoluteTimeGetCurrent()

        let method: String
        #if os(macOS)
        method = "ScreenCaptureKit"
        #else
        method = "ReplayKit"
        #endif
        SCLogger.capture.started("region: \(region.map { "\($0)" } ?? "full")")
        AnalyticsManager.shared.track(.captureStarted(method: method))

        do {
            try await captureService.startCapture(region: region)
            HapticManager.captureStarted()
        } catch {
            captureState = .failed(message: error.localizedDescription)
            errorMessage = error.localizedDescription
            SCLogger.capture.failed("startCapture", error: error)
            AnalyticsManager.shared.track(.captureFailed(error: error.localizedDescription))
            HapticManager.captureError()
        }
    }

    func stopCapture() async {
        do {
            if let screenshot = try await captureService.stopCapture() {
                capturedScreenshot = screenshot
                let duration = CFAbsoluteTimeGetCurrent() - captureStartTime
                SCLogger.capture.completed("frames: \(screenshot.metadata.frameCount)", duration: duration)
                AnalyticsManager.shared.track(.captureCompleted(frames: screenshot.metadata.frameCount, duration: duration))
                HapticManager.captureStopped()
            }
        } catch {
            captureState = .failed(message: error.localizedDescription)
            errorMessage = error.localizedDescription
            SCLogger.capture.failed("stopCapture", error: error)
            AnalyticsManager.shared.track(.captureFailed(error: error.localizedDescription))
            HapticManager.captureError()
        }
    }

    func cancelCapture() {
        captureService.cancelCapture()
        collectedFrames.removeAll()
        currentPreview = nil
        liveStitchPreview = nil
        captureState = .idle
        SCLogger.capture.info("Capture cancelled by user")
        AnalyticsManager.shared.track(.captureCancelled)
    }

    func reset() {
        capturedScreenshot = nil
        currentPreview = nil
        liveStitchPreview = nil
        errorMessage = nil
        captureState = .idle
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
