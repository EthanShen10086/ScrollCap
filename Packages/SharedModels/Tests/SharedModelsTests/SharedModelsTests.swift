import Testing
@testable import SharedModels
import CoreGraphics

@Test func captureRegionPixelDimensions() {
    let region = CaptureRegion(origin: .zero, size: CGSize(width: 100, height: 200), scale: 2.0)
    #expect(region.pixelWidth == 200)
    #expect(region.pixelHeight == 400)
}

@Test func captureStateIsActive() {
    #expect(CaptureState.idle.isActive == false)
    #expect(CaptureState.capturing(progress: CaptureProgress()).isActive == true)
    #expect(CaptureState.stitching.isActive == true)
    #expect(CaptureState.completed(frameCount: 10).isActive == false)
}

@Test func exportFormatProperties() {
    #expect(ExportFormat.png.fileExtension == "png")
    #expect(ExportFormat.jpeg.supportedCompressionQuality == true)
    #expect(ExportFormat.png.supportedCompressionQuality == false)
}
