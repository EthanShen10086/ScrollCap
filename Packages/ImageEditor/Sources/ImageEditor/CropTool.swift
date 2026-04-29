import CoreGraphics
import Foundation

public struct CropTool: Sendable {
    public init() {}

    public func crop(image: CGImage, to rect: CGRect) -> CGImage? {
        let scaledRect = CGRect(
            x: rect.origin.x,
            y: CGFloat(image.height) - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        return image.cropping(to: scaledRect)
    }

    public func cropToAspectRatio(image: CGImage, ratio: CGFloat) -> CGImage? {
        let imageRatio = CGFloat(image.width) / CGFloat(image.height)

        let cropRect: CGRect
        if imageRatio > ratio {
            let newWidth = CGFloat(image.height) * ratio
            let xOffset = (CGFloat(image.width) - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: CGFloat(image.height))
        } else {
            let newHeight = CGFloat(image.width) / ratio
            let yOffset = (CGFloat(image.height) - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: CGFloat(image.width), height: newHeight)
        }

        return image.cropping(to: cropRect)
    }
}
