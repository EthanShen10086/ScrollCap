import Foundation
import CoreGraphics
import Vision

public actor FrameAligner {
    private var lastFrame: CGImage?
    private var cumulativeOffset: CGPoint = .zero
    private let stitcher: ImageStitcher

    public init(stitcher: ImageStitcher = ImageStitcher()) {
        self.stitcher = stitcher
    }

    public func reset() {
        lastFrame = nil
        cumulativeOffset = .zero
    }

    public struct AlignmentResult: Sendable {
        public let frame: StitchFrame
        public let deltaOffset: CGPoint
        public let isNewContent: Bool
    }

    public func processFrame(_ image: CGImage) async throws -> AlignmentResult? {
        guard let previous = lastFrame else {
            lastFrame = image
            cumulativeOffset = .zero
            return AlignmentResult(
                frame: StitchFrame(image: image, cumulativeOffset: .zero),
                deltaOffset: .zero,
                isNewContent: true
            )
        }

        let delta = try await stitcher.computeAlignment(reference: previous, floating: image)

        guard await stitcher.shouldAcceptFrame(offset: delta) else {
            return nil
        }

        cumulativeOffset = CGPoint(
            x: cumulativeOffset.x + delta.x,
            y: cumulativeOffset.y + delta.y
        )

        lastFrame = image

        return AlignmentResult(
            frame: StitchFrame(image: image, cumulativeOffset: cumulativeOffset),
            deltaOffset: delta,
            isNewContent: true
        )
    }
}
