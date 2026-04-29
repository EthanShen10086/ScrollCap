import Foundation
import CoreGraphics

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
        CGRect(origin: origin, size: size)
    }

    public var pixelWidth: Int {
        Int(size.width * scale)
    }

    public var pixelHeight: Int {
        Int(size.height * scale)
    }
}
