import CoreGraphics
import CoreImage
import Foundation
import SharedModels
import Vision

public actor ImageStitcher {
    private let overlapThreshold: CGFloat
    private let minScrollDelta: CGFloat

    public init(overlapThreshold: CGFloat = 0.05, minScrollDelta: CGFloat = 5.0) {
        self.overlapThreshold = overlapThreshold
        self.minScrollDelta = minScrollDelta
    }

    public func computeAlignment(
        reference: CGImage,
        floating: CGImage
    ) throws -> CGPoint {
        let request = VNTranslationalImageRegistrationRequest(
            targetedCGImage: floating
        )

        let handler = VNSequenceRequestHandler()
        try handler.perform([request], on: reference)

        guard let observation = request.results?.first as? VNImageTranslationAlignmentObservation else {
            throw StitchingError.alignmentFailed
        }

        let transform = observation.alignmentTransform
        return CGPoint(x: transform.tx, y: transform.ty)
    }

    public func shouldAcceptFrame(offset: CGPoint) -> Bool {
        abs(offset.y) > minScrollDelta
    }

    public func stitch(frames: [StitchFrame]) throws -> CGImage {
        guard !frames.isEmpty else {
            throw StitchingError.noFrames
        }

        if frames.count == 1 {
            return frames[0].image
        }

        let totalWidth = frames[0].image.width
        let totalHeight = computeTotalHeight(frames: frames)

        guard let context = CGContext(
            data: nil,
            width: totalWidth,
            height: totalHeight,
            bitsPerComponent: 8,
            bytesPerRow: totalWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw StitchingError.contextCreationFailed
        }

        var currentY: CGFloat = 0
        for (index, frame) in frames.enumerated() {
            let drawY = CGFloat(totalHeight) - currentY - CGFloat(frame.image.height)
            let drawRect = CGRect(
                x: 0,
                y: drawY,
                width: CGFloat(frame.image.width),
                height: CGFloat(frame.image.height)
            )

            if index > 0 {
                let overlapHeight = CGFloat(frame.image.height) -
                    abs(frame.cumulativeOffset.y - frames[index - 1].cumulativeOffset.y)
                if overlapHeight > 0 {
                    context.saveGState()
                    context.clip(to: CGRect(
                        x: 0,
                        y: drawY,
                        width: CGFloat(totalWidth),
                        height: CGFloat(frame.image.height) - overlapHeight
                    ))
                    context.draw(frame.image, in: drawRect)
                    context.restoreGState()
                    currentY += CGFloat(frame.image.height) - overlapHeight
                    continue
                }
            }

            context.draw(frame.image, in: drawRect)
            currentY += CGFloat(frame.image.height)
        }

        guard let result = context.makeImage() else {
            throw StitchingError.contextCreationFailed
        }

        return result
    }

    private func computeTotalHeight(frames: [StitchFrame]) -> Int {
        guard frames.count > 1 else {
            return frames.first?.image.height ?? 0
        }

        var height = CGFloat(frames[0].image.height)
        for i in 1 ..< frames.count {
            let delta = abs(frames[i].cumulativeOffset.y - frames[i - 1].cumulativeOffset.y)
            height += delta
        }

        return Int(ceil(height))
    }
}

public struct StitchFrame: Sendable {
    public let image: CGImage
    public let cumulativeOffset: CGPoint

    public init(image: CGImage, cumulativeOffset: CGPoint) {
        self.image = image
        self.cumulativeOffset = cumulativeOffset
    }
}

public enum StitchingError: Error, LocalizedError {
    case alignmentFailed
    case noFrames
    case contextCreationFailed
    case insufficientOverlap

    public var errorDescription: String? {
        switch self {
        case .alignmentFailed: "Failed to compute image alignment"
        case .noFrames: "No frames to stitch"
        case .contextCreationFailed: "Failed to create graphics context"
        case .insufficientOverlap: "Insufficient overlap between frames"
        }
    }
}
