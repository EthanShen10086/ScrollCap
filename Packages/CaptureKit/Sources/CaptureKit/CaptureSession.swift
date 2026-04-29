import CoreGraphics
import Foundation
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
        self.state = .idle
        self.capturedFrames.removeAll()
        self.previewImage = nil
        self.startTime = nil
    }

    public func updateState(_ newState: CaptureState) {
        self.state = newState
    }

    public func addFrame(_ frame: CaptureFrame) {
        self.capturedFrames.append(frame)
    }

    public func updatePreview(_ image: CGImage) {
        self.previewImage = image
    }

    public func markStarted() {
        self.startTime = Date()
    }

    public var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    public var progress: CaptureProgress {
        CaptureProgress(
            capturedFrames: self.capturedFrames.count,
            estimatedHeight: self.capturedFrames.reduce(0) { $0 + $1.offset.y },
            elapsedTime: self.elapsedTime
        )
    }
}
