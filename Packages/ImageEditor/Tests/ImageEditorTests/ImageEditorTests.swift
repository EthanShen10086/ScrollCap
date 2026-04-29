import CoreGraphics
import XCTest
@testable import ImageEditor

final class ImageEditorTests: XCTestCase {
    private func makeTestImage(width: Int, height: Int) -> CGImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    func testCropToolCropsImage() {
        guard let image = makeTestImage(width: 400, height: 800) else {
            XCTFail("Failed to create test image")
            return
        }

        let tool = CropTool()
        let cropped = tool.crop(image: image, to: CGRect(x: 0, y: 0, width: 400, height: 400))
        XCTAssertNotNil(cropped)
        XCTAssertEqual(cropped?.width, 400)
        XCTAssertEqual(cropped?.height, 400)
    }

    func testAnnotationColorCGColor() {
        let red = AnnotationColor.red.cgColor
        XCTAssertEqual(red.numberOfComponents, 4)
    }
}
