import CoreGraphics
import XCTest
@testable import CaptureKit

final class CaptureKitTests: XCTestCase {
    func testCaptureFrameProperties() {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: 200, height: 300,
            bitsPerComponent: 8, bytesPerRow: 200 * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            XCTFail("Failed to create test image")
            return
        }

        let frame = CaptureFrame(image: image, timestamp: 1.0, offset: CGPoint(x: 0, y: 50))
        XCTAssertEqual(frame.width, 200)
        XCTAssertEqual(frame.height, 300)
        XCTAssertEqual(frame.offset.y, 50)
    }

    @MainActor
    func testCaptureSessionInitialState() {
        let session = CaptureSession()
        XCTAssertEqual(session.state, .idle)
        XCTAssertTrue(session.capturedFrames.isEmpty)
        XCTAssertNil(session.previewImage)
    }
}
