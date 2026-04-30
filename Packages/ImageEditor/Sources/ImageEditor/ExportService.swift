import CoreGraphics
import Foundation
import ImageIO
import SharedModels
import UniformTypeIdentifiers

public actor ExportService {
    public init() {}

    public func export(
        image: CGImage,
        options: ExportOptions,
        to url: URL
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            let utType = options.format.utType

            guard let destination = CGImageDestinationCreateWithURL(
                url as CFURL,
                utType.identifier as CFString,
                1,
                nil
            ) else {
                throw ExportError.destinationCreationFailed
            }

            var properties: [CFString: Any] = [:]

            if options.format.supportedCompressionQuality {
                properties[kCGImageDestinationLossyCompressionQuality] = options.compressionQuality
            }

            if options.scale != 1.0 {
                properties[kCGImagePropertyDPIWidth] = 72.0 * options.scale
                properties[kCGImagePropertyDPIHeight] = 72.0 * options.scale
            }

            CGImageDestinationAddImage(destination, image, properties as CFDictionary)

            guard CGImageDestinationFinalize(destination) else {
                throw ExportError.finalizationFailed
            }
        }.value
    }

    public func exportToData(
        image: CGImage,
        options: ExportOptions
    ) async throws -> Data {
        try await Task.detached(priority: .userInitiated) {
            let data = NSMutableData()
            let utType = options.format.utType

            guard let destination = CGImageDestinationCreateWithData(
                data,
                utType.identifier as CFString,
                1,
                nil
            ) else {
                throw ExportError.destinationCreationFailed
            }

            var properties: [CFString: Any] = [:]
            if options.format.supportedCompressionQuality {
                properties[kCGImageDestinationLossyCompressionQuality] = options.compressionQuality
            }

            CGImageDestinationAddImage(destination, image, properties as CFDictionary)

            guard CGImageDestinationFinalize(destination) else {
                throw ExportError.finalizationFailed
            }

            return data as Data
        }.value
    }

    public func suggestedFilename(format: ExportFormat) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        return "ScrollCap_\(timestamp).\(format.fileExtension)"
    }
}

public enum ExportError: Error, LocalizedError {
    case destinationCreationFailed
    case finalizationFailed
    case unsupportedFormat

    public var errorDescription: String? {
        switch self {
        case .destinationCreationFailed: "Failed to create export destination"
        case .finalizationFailed: "Failed to finalize image export"
        case .unsupportedFormat: "Unsupported export format"
        }
    }
}
