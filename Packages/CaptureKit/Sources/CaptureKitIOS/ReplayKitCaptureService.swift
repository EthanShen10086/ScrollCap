#if os(iOS)
import CaptureKit
import CoreGraphics
import Foundation
@preconcurrency import ReplayKit
import SharedModels
import StitchingEngine

@MainActor
public final class ReplayKitCaptureService: NSObject, CaptureService {
    public private(set) var state: CaptureState = .idle
    public private(set) var currentPreview: CGImage?
    public var onStateChanged: ((CaptureState) -> Void)?
    public var onPreviewUpdated: ((CGImage) -> Void)?

    private let session = CaptureSession()
    private let aligner = FrameAligner()
    private var collectedFrames: [StitchFrame] = []
    private let recorder = RPScreenRecorder.shared()
    private var isRecording = false
    private let ciContext = CIContext()

    override public init() {
        super.init()
    }

    public func requestPermission() async -> Bool {
        return RPScreenRecorder.shared().isAvailable
    }

    public func prepare() async throws {
        guard self.recorder.isAvailable else {
            throw ReplayKitError.notAvailable
        }
        self.updateState(.preparing)
    }

    public func startCapture(region: CaptureRegion?) async throws {
        guard !self.isRecording else {
            throw ReplayKitError.alreadyRecording
        }

        await self.aligner.reset()
        self.collectedFrames.removeAll()
        self.session.markStarted()

        let localRecorder = self.recorder
        try await localRecorder.startCapture(handler: { @Sendable sampleBuffer, sampleBufferType, error in
            guard sampleBufferType == .video, error == nil else { return }
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            guard let cgImage = self.ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }

            Task { @MainActor [weak self] in
                await self?.processFrame(cgImage)
            }
        })

        self.isRecording = true
        self.updateState(.capturing(progress: CaptureProgress()))
    }

    public func stopCapture() async throws -> Screenshot? {
        guard self.isRecording else { return nil }

        try await self.recorder.stopCapture()
        self.isRecording = false

        self.updateState(.stitching)

        guard !self.collectedFrames.isEmpty else {
            self.updateState(.failed(message: "No frames captured"))
            return nil
        }

        do {
            let stitcher = ImageStitcher()
            let stitchedImage = try await stitcher.stitch(frames: self.collectedFrames)

            let metadata = ScreenshotMetadata(
                frameCount: collectedFrames.count,
                totalHeight: CGFloat(stitchedImage.height),
                captureMethod: .replayKit,
                durationSeconds: self.session.elapsedTime
            )

            let screenshot = Screenshot(image: stitchedImage, metadata: metadata)
            self.updateState(.completed(frameCount: self.collectedFrames.count))
            return screenshot
        } catch {
            self.updateState(.failed(message: error.localizedDescription))
            return nil
        }
    }

    public func cancelCapture() {
        Task {
            try? await self.recorder.stopCapture()
            self.isRecording = false
            self.collectedFrames.removeAll()
            self.updateState(.idle)
        }
    }

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
            // Skip frames that fail alignment
        }
    }

    private func updateState(_ newState: CaptureState) {
        self.state = newState
        self.session.updateState(newState)
        self.onStateChanged?(newState)
    }
}

public enum ReplayKitError: Error, LocalizedError {
    case notAvailable
    case alreadyRecording
    case broadcastFailed

    public var errorDescription: String? {
        switch self {
        case .notAvailable: "Screen recording is not available"
        case .alreadyRecording: "Already recording"
        case .broadcastFailed: "Broadcast setup failed"
        }
    }
}
#endif
