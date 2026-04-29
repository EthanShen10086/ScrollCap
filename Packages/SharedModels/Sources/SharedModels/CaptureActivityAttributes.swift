#if canImport(ActivityKit)
import ActivityKit
import Foundation

public struct CaptureActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var capturedFrames: Int
        public var elapsedSeconds: Int
        public var estimatedHeight: Int
        public var phase: CapturePhase

        public init(
            capturedFrames: Int = 0,
            elapsedSeconds: Int = 0,
            estimatedHeight: Int = 0,
            phase: CapturePhase = .preparing
        ) {
            self.capturedFrames = capturedFrames
            self.elapsedSeconds = elapsedSeconds
            self.estimatedHeight = estimatedHeight
            self.phase = phase
        }
    }

    public enum CapturePhase: String, Codable, Hashable {
        case preparing
        case capturing
        case stitching
        case completed
        case failed
    }

    public init() {}
}
#endif
