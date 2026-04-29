import Foundation
import CoreGraphics
import SharedModels

@Observable
@MainActor
public final class CaptureSession {
    public private(set) var state: CaptureState = .idle
    public private(set) var capturedFrames: [CaptureFrame] = []
    public private(set) var previewImage: CGImage?
    public private(set) var startTime: Date?

    public init() {}

    public func reset() {
        state = .idle
        capturedFrames.removeAll()
        previewImage = nil
        startTime = nil
    }

    public func updateState(_ newState: CaptureState) {
        state = newState
    }

    public func addFrame(_ frame: CaptureFrame) {
        capturedFrames.append(frame)
    }

    public func updatePreview(_ image: CGImage) {
        previewImage = image
    }

    public func markStarted() {
        startTime = Date()
    }

    public var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    public var progress: CaptureProgress {
        CaptureProgress(
            capturedFrames: capturedFrames.count,
            estimatedHeight: capturedFrames.reduce(0) { $0 + $1.offset.y },
            elapsedTime: elapsedTime
        )
    }
}
