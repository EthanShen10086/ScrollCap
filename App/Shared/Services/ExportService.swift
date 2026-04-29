import CoreGraphics
import Foundation
import ImageIO
import SharedModels
import UniformTypeIdentifiers

struct ExportService {
    func export(image: CGImage, options: ExportOptions, to url: URL) async throws {
        let signpostID = PerformanceMonitor.beginExport(format: options.format.rawValue)
        defer { PerformanceMonitor.endExport(signpostID) }

        let data = try await self.exportToData(image: image, options: options)
        guard let data else {
            throw SCError.export(.fileWriteFailed)
        }
        try data.write(to: url, options: .atomic)
    }

    func exportToData(image: CGImage, options: ExportOptions) async throws -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            options.format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw SCError.export(.fileWriteFailed)
        }

        var properties: [CFString: Any] = [:]
        if options.format.supportedCompressionQuality {
            properties[kCGImageDestinationLossyCompressionQuality] = options.compressionQuality
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw SCError.export(.fileWriteFailed)
        }

        return data as Data
    }
}
