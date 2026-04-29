import Foundation
import UniformTypeIdentifiers

public enum ExportFormat: String, CaseIterable, Identifiable, Sendable {
    case png
    case jpeg
    case heic
    case pdf

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .png: "PNG"
        case .jpeg: "JPEG"
        case .heic: "HEIC"
        case .pdf: "PDF"
        }
    }

    public var fileExtension: String {
        rawValue
    }

    public var utType: UTType {
        switch self {
        case .png: .png
        case .jpeg: .jpeg
        case .heic: .heic
        case .pdf: .pdf
        }
    }

    public var supportedCompressionQuality: Bool {
        self == .jpeg || self == .heic
    }
}

public struct ExportOptions: Sendable {
    public let format: ExportFormat
    public let compressionQuality: Double
    public let scale: CGFloat

    public init(
        format: ExportFormat = .png,
        compressionQuality: Double = 0.9,
        scale: CGFloat = 1.0
    ) {
        self.format = format
        self.compressionQuality = compressionQuality
        self.scale = scale
    }
}
