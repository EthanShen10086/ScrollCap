import XCTest
@testable import StitchingEngine
import CoreGraphics

final class StitchingEngineTests: XCTestCase {
    private func makeTestImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        return context.makeImage()
    }

    func testStitchFrameProperties() {
        guard let image = makeTestImage(width: 100, height: 200) else {
            XCTFail("Failed to create test image")
            return
        }

        let frame = StitchFrame(image: image, cumulativeOffset: CGPoint(x: 0, y: 100))
        XCTAssertEqual(frame.image.width, 100)
        XCTAssertEqual(frame.image.height, 200)
        XCTAssertEqual(frame.cumulativeOffset.y, 100)
    }

    func testStitchResultAspectRatio() {
        guard let image = makeTestImage(width: 100, height: 400) else {
            XCTFail("Failed to create test image")
            return
        }

        let result = StitchResult(image: image, frameCount: 5, totalHeight: 400, processingTime: 1.0)
        XCTAssertEqual(result.aspectRatio, 0.25)
    }

    func testSingleFrameStitch() async throws {
        guard let image = makeTestImage(width: 200, height: 300) else {
            XCTFail("Failed to create test image")
            return
        }

        let stitcher = ImageStitcher()
        let frames = [StitchFrame(image: image, cumulativeOffset: .zero)]
        let result = try await stitcher.stitch(frames: frames)
        XCTAssertEqual(result.width, 200)
        XCTAssertEqual(result.height, 300)
    }
}
