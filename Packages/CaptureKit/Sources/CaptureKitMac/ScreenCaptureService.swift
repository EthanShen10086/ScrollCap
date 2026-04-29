#if os(macOS)
import CaptureKit
import CoreGraphics
import Foundation
@preconcurrency import ScreenCaptureKit
import SharedModels
import StitchingEngine

@MainActor
public final class ScreenCaptureService: NSObject, CaptureService {
    public private(set) var state: CaptureState = .idle
    public private(set) var currentPreview: CGImage?
    public var onStateChanged: ((CaptureState) -> Void)?
    public var onPreviewUpdated: ((CGImage) -> Void)?

    private var stream: SCStream?
    private var filter: SCContentFilter?
    private let session = CaptureSession()
    private let aligner = FrameAligner()
    private var collectedFrames: [StitchFrame] = []

    override public init() {
        super.init()
    }

    public func requestPermission() async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return !content.displays.isEmpty
        } catch {
            return false
        }
    }

    public func prepare() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard content.displays.first != nil else {
            throw CaptureServiceError.noDisplayFound
        }
        self.updateState(.selectingRegion)
    }

    public func startCapture(region: CaptureRegion?) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw CaptureServiceError.noDisplayFound
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        self.filter = filter

        let config = SCStreamConfiguration()
        config.width = region?.pixelWidth ?? display.width
        config.height = region?.pixelHeight ?? display.height

        if let region {
            config.sourceRect = region.rect
        }

        config.minimumFrameInterval = CMTime(value: 1, timescale: 10) // 10 fps
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false

        let stream = SCStream(filter: filter, configuration: config, delegate: nil)
        self.stream = stream

        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
        try await stream.startCapture()

        await self.aligner.reset()
        self.collectedFrames.removeAll()
        self.session.markStarted()
        self.updateState(.capturing(progress: CaptureProgress()))
    }

    public func stopCapture() async throws -> Screenshot? {
        guard let stream else { return nil }

        try await stream.stopCapture()
        self.stream = nil

        self.updateState(.stitching)

        let stitcher = ImageStitcher()
        let startTime = CFAbsoluteTimeGetCurrent()

        guard !self.collectedFrames.isEmpty else {
            self.updateState(.failed(message: "No frames captured"))
            return nil
        }

        do {
            let stitchedImage = try await stitcher.stitch(frames: self.collectedFrames)
            _ = CFAbsoluteTimeGetCurrent() - startTime

            let metadata = ScreenshotMetadata(
                frameCount: collectedFrames.count,
                totalHeight: CGFloat(stitchedImage.height),
                captureMethod: .screenCaptureKit,
                durationSeconds: self.session.elapsedTime
            )

            let screenshot = Screenshot(
                image: stitchedImage,
                metadata: metadata
            )

            self.updateState(.completed(frameCount: self.collectedFrames.count))
            return screenshot
        } catch {
            self.updateState(.failed(message: error.localizedDescription))
            return nil
        }
    }

    public func cancelCapture() {
        Task {
            try? await self.stream?.stopCapture()
            self.stream = nil
            self.collectedFrames.removeAll()
            self.updateState(.idle)
        }
    }

    private func updateState(_ newState: CaptureState) {
        self.state = newState
        self.session.updateState(newState)
        self.onStateChanged?(newState)
    }
}

extension ScreenCaptureService: SCStreamOutput {
    public nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        Task { @MainActor in
            await self.processFrame(cgImage)
        }
    }

    @MainActor
    private func processFrame(_ image: CGImage) async {
        do {
            if let result = try await aligner.processFrame(image) {
                self.collectedFrames.append(result.frame)
                self.currentPreview = image
                self.onPreviewUpdated?(image)

                let progress = CaptureProgress(
                    capturedFrames: collectedFrames.count,
                    estimatedHeight: result.frame.cumulativeOffset.y,
                    elapsedTime: self.session.elapsedTime
                )
                self.updateState(.capturing(progress: progress))
            }
        } catch {
            // Frame alignment failed for this frame, skip it
        }
    }
}

public enum CaptureServiceError: Error, LocalizedError {
    case noDisplayFound
    case permissionDenied
    case captureAlreadyRunning

    public var errorDescription: String? {
        switch self {
        case .noDisplayFound: "No display found for capture"
        case .permissionDenied: "Screen recording permission denied"
        case .captureAlreadyRunning: "A capture session is already running"
        }
    }
}
#endif
