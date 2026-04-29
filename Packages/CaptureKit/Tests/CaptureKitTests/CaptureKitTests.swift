import Testing
@testable import CaptureKit
import CoreGraphics

@Test func captureFrameProperties() {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil, width: 200, height: 300,
        bitsPerComponent: 8, bytesPerRow: 200 * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let image = context.makeImage() else {
        Issue.record("Failed to create test image")
        return
    }

    let frame = CaptureFrame(image: image, timestamp: 1.0, offset: CGPoint(x: 0, y: 50))
    #expect(frame.width == 200)
    #expect(frame.height == 300)
    #expect(frame.offset.y == 50)
}

@Test @MainActor func captureSessionInitialState() {
    let session = CaptureSession()
    #expect(session.state == .idle)
    #expect(session.capturedFrames.isEmpty)
    #expect(session.previewImage == nil)
}
