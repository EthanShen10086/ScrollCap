import CoreGraphics
import Foundation

public enum AnnotationType: Sendable {
    case rectangle(color: AnnotationColor, lineWidth: CGFloat)
    case arrow(from: CGPoint, to: CGPoint, color: AnnotationColor, lineWidth: CGFloat)
    case text(String, position: CGPoint, fontSize: CGFloat, color: AnnotationColor)
    case highlight(rect: CGRect, color: AnnotationColor, opacity: CGFloat)
    case blur(rect: CGRect, radius: CGFloat)
}

public enum AnnotationColor: Sendable {
    case red, blue, green, yellow, white, black, custom(red: CGFloat, green: CGFloat, blue: CGFloat)

    public var cgColor: CGColor {
        switch self {
        case .red: CGColor(red: 1, green: 0, blue: 0, alpha: 1)
        case .blue: CGColor(red: 0, green: 0.47, blue: 1, alpha: 1)
        case .green: CGColor(red: 0, green: 0.78, blue: 0.33, alpha: 1)
        case .yellow: CGColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        case .white: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        case .black: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        case let .custom(red, green, blue): CGColor(red: red, green: green, blue: blue, alpha: 1)
        }
    }
}

public struct Annotation: Identifiable, Sendable {
    public let id: UUID
    public let type: AnnotationType
    public let rect: CGRect

    public init(id: UUID = UUID(), type: AnnotationType, rect: CGRect) {
        self.id = id
        self.type = type
        self.rect = rect
    }
}

public actor AnnotationRenderer {
    public init() {}

    public func render(annotations: [Annotation], onto image: CGImage) -> CGImage? {
        let width = image.width
        let height = image.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        for annotation in annotations {
            self.renderAnnotation(annotation, in: context, imageHeight: height)
        }

        return context.makeImage()
    }

    private func renderAnnotation(_ annotation: Annotation, in context: CGContext, imageHeight: Int) {
        switch annotation.type {
        case let .rectangle(color, lineWidth):
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.stroke(annotation.rect)

        case let .arrow(from, to, color, lineWidth):
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(lineWidth)
            context.move(to: from)
            context.addLine(to: to)
            context.strokePath()

        case let .highlight(_, color, opacity):
            context.setFillColor(color.cgColor.copy(alpha: opacity) ?? color.cgColor)
            context.fill(annotation.rect)

        case .text, .blur:
            break
        }
    }
}
