import CoreGraphics
import Foundation
import ImageIO

public struct Screenshot: Identifiable, Sendable {
    public let id: UUID
    public let image: CGImage
    public let createdAt: Date
    public let sourceRegion: CaptureRegion?
    public let metadata: ScreenshotMetadata

    private let _thumbnail: CGImage

    public var thumbnail: CGImage {
        self._thumbnail
    }

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
        self._thumbnail = Screenshot.generateThumbnail(from: image, maxDimension: 400)
    }

    private static func generateThumbnail(from image: CGImage, maxDimension: CGFloat) -> CGImage {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let scale = min(maxDimension / width, maxDimension / height, 1.0)

        guard scale < 1.0 else { return image }

        let newWidth = Int(width * scale)
        let newHeight = Int(height * scale)

        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else { return image }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return context.makeImage() ?? image
    }

    public var pngData: Data? {
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            mutableData as CFMutableData, "public.png" as CFString, 1, nil
        ) else { return nil }
        CGImageDestinationAddImage(dest, self.image, nil)
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

    public var localizedName: String {
        switch self {
        case .screenCaptureKit: String(localized: "method.screenCaptureKit")
        case .replayKit: String(localized: "method.replayKit")
        case .unknown: String(localized: "method.unknown")
        }
    }
}
