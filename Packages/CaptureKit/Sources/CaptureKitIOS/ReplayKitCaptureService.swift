#if os(iOS)
import Foundation
import CoreGraphics
@preconcurrency import ReplayKit
import SharedModels
import CaptureKit
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

    public override init() {
        super.init()
    }

    public func requestPermission() async -> Bool {
        return RPScreenRecorder.shared().isAvailable
    }

    public func prepare() async throws {
        guard recorder.isAvailable else {
            throw ReplayKitError.notAvailable
        }
        updateState(.preparing)
    }

    public func startCapture(region: CaptureRegion?) async throws {
        guard !isRecording else {
            throw ReplayKitError.alreadyRecording
        }

        await aligner.reset()
        collectedFrames.removeAll()
        session.markStarted()

        let localRecorder = recorder
        try await localRecorder.startCapture(handler: { @Sendable sampleBuffer, sampleBufferType, error in
            guard sampleBufferType == .video, error == nil else { return }
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

            Task { @MainActor [weak self] in
                await self?.processFrame(cgImage)
            }
        })

        isRecording = true
        updateState(.capturing(progress: CaptureProgress()))
    }

    public func stopCapture() async throws -> Screenshot? {
        guard isRecording else { return nil }

        try await recorder.stopCapture()
        isRecording = false

        updateState(.stitching)

        guard !collectedFrames.isEmpty else {
            updateState(.failed(message: "No frames captured"))
            return nil
        }

        do {
            let stitcher = ImageStitcher()
            let stitchedImage = try await stitcher.stitch(frames: collectedFrames)

            let metadata = ScreenshotMetadata(
                frameCount: collectedFrames.count,
                totalHeight: CGFloat(stitchedImage.height),
                captureMethod: .replayKit,
                durationSeconds: session.elapsedTime
            )

            let screenshot = Screenshot(image: stitchedImage, metadata: metadata)
            updateState(.completed(frameCount: collectedFrames.count))
            return screenshot
        } catch {
            updateState(.failed(message: error.localizedDescription))
            return nil
        }
    }

    public func cancelCapture() {
        Task {
            try? await recorder.stopCapture()
            isRecording = false
            collectedFrames.removeAll()
            updateState(.idle)
        }
    }

    private func processFrame(_ image: CGImage) async {
        do {
            if let result = try await aligner.processFrame(image) {
                collectedFrames.append(result.frame)
                currentPreview = image
                onPreviewUpdated?(image)

                let progress = CaptureProgress(
                    capturedFrames: collectedFrames.count,
                    estimatedHeight: result.frame.cumulativeOffset.y,
                    elapsedTime: session.elapsedTime
                )
                updateState(.capturing(progress: progress))
            }
        } catch {
            // Skip frames that fail alignment
        }
    }

    private func updateState(_ newState: CaptureState) {
        state = newState
        session.updateState(newState)
        onStateChanged?(newState)
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
