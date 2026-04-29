import CoreGraphics
import Foundation
import ImageIO
import OSLog

@MainActor
@Observable
final class ICloudSyncManager {
    static let shared = ICloudSyncManager()

    private(set) var syncState: SyncState = .idle
    private(set) var lastSyncDate: Date?

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "icloud")
    private var metadataQuery: NSMetadataQuery?

    enum SyncState: Equatable {
        case idle
        case syncing
        case synced
        case error(String)
        case disabled
    }

    private init() {}

    var iCloudContainerURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: "iCloud.com.ethanshen.scrollcap")
    }

    var isAvailable: Bool {
        self.iCloudContainerURL != nil
    }

    var documentsURL: URL? {
        self.iCloudContainerURL?.appendingPathComponent("Documents/Screenshots", isDirectory: true)
    }

    var manifestURL: URL? {
        self.iCloudContainerURL?.appendingPathComponent("Documents/manifest.json")
    }

    func startMonitoring() {
        guard self.isAvailable else {
            self.syncState = .disabled
            self.logger.info("iCloud not available")
            return
        }

        self.ensureDirectoryExists()
        self.startMetadataQuery()
        self.logger.info("iCloud sync monitoring started")
    }

    func stopMonitoring() {
        self.metadataQuery?.stop()
        self.metadataQuery = nil
    }

    func syncScreenshot(imageData: Data, record: ScreenshotSyncRecord) async {
        guard let documentsURL else { return }

        self.syncState = .syncing
        AnalyticsManager.shared.track(.iCloudSyncStarted)

        let fileURL = documentsURL.appendingPathComponent(record.filename)
        do {
            try imageData.write(to: fileURL)
            try await self.updateManifest(adding: record)
            self.syncState = .synced
            self.lastSyncDate = Date()
            self.logger.completed("Synced \(record.filename)")
            AnalyticsManager.shared.track(.iCloudSyncCompleted(itemCount: 1))
        } catch {
            self.syncState = .error(error.localizedDescription)
            self.logger.failed("Sync failed", error: error)
            AnalyticsManager.shared.track(.iCloudSyncFailed(error: error.localizedDescription))
        }
    }

    func fetchRemoteScreenshots() async -> [ScreenshotSyncRecord] {
        guard let manifestURL else { return [] }

        do {
            let coordinator = NSFileCoordinator()
            var data: Data?
            var coordinatorError: NSError?

            coordinator.coordinate(readingItemAt: manifestURL, options: [], error: &coordinatorError) { url in
                data = try? Data(contentsOf: url)
            }

            if let coordinatorError {
                throw coordinatorError
            }

            guard let data else { return [] }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([ScreenshotSyncRecord].self, from: data)
        } catch {
            self.logger.failed("Failed to fetch remote manifest", error: error)
            return []
        }
    }

    // MARK: - Private

    private func ensureDirectoryExists() {
        guard let documentsURL else { return }
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }

    private func startMetadataQuery() {
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K LIKE '*.png'", NSMetadataItemFSNameKey)

        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidFinishGathering,
            object: query,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.processQueryResults()
            }
        }

        NotificationCenter.default.addObserver(
            forName: .NSMetadataQueryDidUpdate,
            object: query,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.processQueryResults()
            }
        }

        query.start()
        self.metadataQuery = query
    }

    private func processQueryResults() {
        guard let query = metadataQuery else { return }
        query.disableUpdates()
        let itemCount = query.resultCount
        self.logger.info("iCloud query update: \(itemCount) items")
        query.enableUpdates()
    }

    private func updateManifest(adding record: ScreenshotSyncRecord) async throws {
        guard let manifestURL else { return }

        var records = await fetchRemoteScreenshots()
        records.insert(record, at: 0)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(records)

        let coordinator = NSFileCoordinator()
        var coordinatorError: NSError?

        coordinator.coordinate(writingItemAt: manifestURL, options: .forReplacing, error: &coordinatorError) { url in
            try? data.write(to: url)
        }

        if let coordinatorError {
            throw coordinatorError
        }
    }
}

// MARK: - Sync Record

struct ScreenshotSyncRecord: Codable, Identifiable {
    let id: UUID
    let filename: String
    let createdAt: Date
    let width: Int
    let height: Int
    let frameCount: Int
    let captureMethod: String
    let durationSeconds: TimeInterval
}
