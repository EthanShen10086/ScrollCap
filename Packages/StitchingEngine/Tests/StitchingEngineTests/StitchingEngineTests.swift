import Testing
@testable import StitchingEngine
import CoreGraphics

@Test func stitchFrameProperties() {
    let width = 100
    let height = 200
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil, width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let image = context.makeImage() else {
        Issue.record("Failed to create test image")
        return
    }

    let frame = StitchFrame(image: image, cumulativeOffset: CGPoint(x: 0, y: 100))
    #expect(frame.image.width == 100)
    #expect(frame.image.height == 200)
    #expect(frame.cumulativeOffset.y == 100)
}

@Test func stitchResultAspectRatio() {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil, width: 100, height: 400,
        bitsPerComponent: 8, bytesPerRow: 100 * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let image = context.makeImage() else {
        Issue.record("Failed to create test image")
        return
    }

    let result = StitchResult(image: image, frameCount: 5, totalHeight: 400, processingTime: 1.0)
    #expect(result.aspectRatio == 0.25)
}
