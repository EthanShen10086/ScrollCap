import CoreGraphics
import Foundation

public struct CaptureRegion: Sendable, Codable, Equatable {
    public let origin: CGPoint
    public let size: CGSize
    public let scale: CGFloat

    public init(origin: CGPoint, size: CGSize, scale: CGFloat = 1.0) {
        self.origin = origin
        self.size = size
        self.scale = scale
    }

    public var rect: CGRect {
        CGRect(origin: self.origin, size: self.size)
    }

    public var pixelWidth: Int {
        Int(self.size.width * self.scale)
    }

    public var pixelHeight: Int {
        Int(self.size.height * self.scale)
    }
}
