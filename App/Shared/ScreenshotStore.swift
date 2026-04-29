import Foundation
import CoreGraphics
import ImageIO
import SharedModels

actor ScreenshotStore {
    private let storageDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        storageDirectory = appSupport.appendingPathComponent("ScrollCap/Screenshots", isDirectory: true)

        try? FileManager.default.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    struct ScreenshotRecord: Codable, Identifiable {
        let id: UUID
        let filename: String
        let createdAt: Date
        let width: Int
        let height: Int
        let frameCount: Int
        let captureMethod: String
        let durationSeconds: TimeInterval
    }

    private var manifestURL: URL {
        storageDirectory.appendingPathComponent("manifest.json")
    }

    func save(screenshot: Screenshot) throws {
        let filename = "\(screenshot.id.uuidString).png"
        let fileURL = storageDirectory.appendingPathComponent(filename)

        guard let destination = CGImageDestinationCreateWithURL(
            fileURL as CFURL, "public.png" as CFString, 1, nil
        ) else { return }

        CGImageDestinationAddImage(destination, screenshot.image, nil)
        CGImageDestinationFinalize(destination)

        let record = ScreenshotRecord(
            id: screenshot.id,
            filename: filename,
            createdAt: screenshot.createdAt,
            width: screenshot.image.width,
            height: screenshot.image.height,
            frameCount: screenshot.metadata.frameCount,
            captureMethod: screenshot.metadata.captureMethod.rawValue,
            durationSeconds: screenshot.metadata.durationSeconds
        )

        var records = (try? loadManifest()) ?? []
        records.insert(record, at: 0)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(records)
        try data.write(to: manifestURL)
    }

    func loadAll() throws -> [(record: ScreenshotRecord, image: CGImage)] {
        let records = try loadManifest()
        var results: [(ScreenshotRecord, CGImage)] = []

        for record in records {
            let fileURL = storageDirectory.appendingPathComponent(record.filename)
            guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                continue
            }
            results.append((record, image))
        }

        return results
    }

    func delete(id: UUID) throws {
        var records = (try? loadManifest()) ?? []
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        let record = records[index]
        let fileURL = storageDirectory.appendingPathComponent(record.filename)
        try? FileManager.default.removeItem(at: fileURL)

        records.remove(at: index)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(records)
        try data.write(to: manifestURL)
    }

    func deleteAll() throws {
        let records = (try? loadManifest()) ?? []
        for record in records {
            let fileURL = storageDirectory.appendingPathComponent(record.filename)
            try? FileManager.default.removeItem(at: fileURL)
        }
        try? FileManager.default.removeItem(at: manifestURL)
    }

    private func loadManifest() throws -> [ScreenshotRecord] {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return []
        }

        let data = try Data(contentsOf: manifestURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ScreenshotRecord].self, from: data)
    }
}
