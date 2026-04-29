import CoreGraphics
import XCTest
@testable import SharedModels

final class SharedModelsTests: XCTestCase {
    func testCaptureRegionPixelDimensions() {
        let region = CaptureRegion(origin: .zero, size: CGSize(width: 100, height: 200), scale: 2.0)
        XCTAssertEqual(region.pixelWidth, 200)
        XCTAssertEqual(region.pixelHeight, 400)
    }

    func testCaptureStateIsActive() {
        XCTAssertFalse(CaptureState.idle.isActive)
        XCTAssertTrue(CaptureState.capturing(progress: CaptureProgress()).isActive)
        XCTAssertTrue(CaptureState.stitching.isActive)
        XCTAssertFalse(CaptureState.completed(frameCount: 10).isActive)
    }

    func testExportFormatProperties() {
        XCTAssertEqual(ExportFormat.png.fileExtension, "png")
        XCTAssertTrue(ExportFormat.jpeg.supportedCompressionQuality)
        XCTAssertFalse(ExportFormat.png.supportedCompressionQuality)
    }
}
