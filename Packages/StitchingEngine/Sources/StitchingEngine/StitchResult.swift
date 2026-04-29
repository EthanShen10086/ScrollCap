import Foundation
import CoreGraphics

public struct StitchResult: Sendable {
    public let image: CGImage
    public let frameCount: Int
    public let totalHeight: Int
    public let processingTime: TimeInterval

    public init(
        image: CGImage,
        frameCount: Int,
        totalHeight: Int,
        processingTime: TimeInterval
    ) {
        self.image = image
        self.frameCount = frameCount
        self.totalHeight = totalHeight
        self.processingTime = processingTime
    }

    public var aspectRatio: CGFloat {
        guard totalHeight > 0 else { return 1 }
        return CGFloat(image.width) / CGFloat(totalHeight)
    }
}
