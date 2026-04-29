import CoreGraphics
import Foundation
import ImageIO

public struct Screenshot: Identifiable, Sendable {
    public let id: UUID
    public let image: CGImage
    public let createdAt: Date
    public let sourceRegion: CaptureRegion?
    public let metadata: ScreenshotMetadata

    public init(
        id: UUID = UUID(),
        image: CGImage,
        createdAt: Date = Date(),
        sourceRegion: CaptureRegion? = nil,
        metadata: ScreenshotMetadata = ScreenshotMetadata()
    ) {
        self.id = id
        self.image = image
        self.createdAt = createdAt
        self.sourceRegion = sourceRegion
        self.metadata = metadata
    }

    public var pngData: Data? {
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            mutableData as CFMutableData, "public.png" as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(dest, image, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return mutableData as Data
    }
}

public struct ScreenshotMetadata: Sendable {
    public let frameCount: Int
    public let totalHeight: CGFloat
    public let captureMethod: CaptureMethod
    public let durationSeconds: TimeInterval

    public init(
        frameCount: Int = 0,
        totalHeight: CGFloat = 0,
        captureMethod: CaptureMethod = .unknown,
        durationSeconds: TimeInterval = 0
    ) {
        self.frameCount = frameCount
        self.totalHeight = totalHeight
        self.captureMethod = captureMethod
        self.durationSeconds = durationSeconds
    }
}

public enum CaptureMethod: String, Sendable, Codable {
    case screenCaptureKit
    case replayKit
    case unknown
}
