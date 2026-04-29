import Foundation
import CoreGraphics

public enum CaptureState: Sendable, Equatable {
    case idle
    case selectingRegion
    case preparing
    case capturing(progress: CaptureProgress)
    case stitching
    case completed(frameCount: Int)
    case failed(message: String)

    public var isActive: Bool {
        switch self {
        case .capturing, .stitching, .preparing, .selectingRegion:
            return true
        case .idle, .completed, .failed:
            return false
        }
    }

    public var isCapturing: Bool {
        if case .capturing = self { return true }
        return false
    }

    public var statusKey: String {
        switch self {
        case .idle: "idle"
        case .selectingRegion: "selecting"
        case .preparing: "preparing"
        case .capturing: "capturing"
        case .stitching: "stitching"
        case .completed: "completed"
        case .failed: "failed"
        }
    }
}

public struct CaptureProgress: Sendable, Equatable {
    public let capturedFrames: Int
    public let estimatedHeight: CGFloat
    public let elapsedTime: TimeInterval

    public init(
        capturedFrames: Int = 0,
        estimatedHeight: CGFloat = 0,
        elapsedTime: TimeInterval = 0
    ) {
        self.capturedFrames = capturedFrames
        self.estimatedHeight = estimatedHeight
        self.elapsedTime = elapsedTime
    }
}
