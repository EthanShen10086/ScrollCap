import CoreGraphics
import Foundation

public struct CaptureFrame: Sendable, Identifiable {
    public let id: UUID
    public let image: CGImage
    public let timestamp: TimeInterval
    public let offset: CGPoint

    public init(
        id: UUID = UUID(),
        image: CGImage,
        timestamp: TimeInterval,
        offset: CGPoint = .zero
    ) {
        self.id = id
        self.image = image
        self.timestamp = timestamp
        self.offset = offset
    }

    public var width: Int {
        self.image.width
    }

    public var height: Int {
        self.image.height
    }
}
