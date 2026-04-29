import Testing
@testable import ImageEditor
import CoreGraphics

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

@Test func cropToolCropsImage() {
    guard let image = makeTestImage(width: 400, height: 800) else {
        Issue.record("Failed to create test image")
        return
    }

    let tool = CropTool()
    let cropped = tool.crop(image: image, to: CGRect(x: 0, y: 0, width: 400, height: 400))
    #expect(cropped != nil)
    #expect(cropped?.width == 400)
    #expect(cropped?.height == 400)
}

@Test func annotationColorCGColor() {
    let red = AnnotationColor.red.cgColor
    #expect(red.numberOfComponents == 4)
}
