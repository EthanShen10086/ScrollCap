#if os(iOS)
import Foundation
import CoreGraphics
import ImageIO

@MainActor
final class SharedFrameReader {
    private let appGroupID = "group.com.scrollcap.shared"
    private var lastReadFrameCount = 0
    private var timer: Timer?
    var onNewFrame: ((CGImage) -> Void)?

    func startMonitoring() {
        lastReadFrameCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkForNewFrames()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    var isBroadcasting: Bool {
        let defaults = UserDefaults(suiteName: appGroupID)
        return defaults?.bool(forKey: "isBroadcasting") ?? false
    }

    var currentFrameCount: Int {
        let defaults = UserDefaults(suiteName: appGroupID)
        return defaults?.integer(forKey: "currentFrameCount") ?? 0
    }

    private func checkForNewFrames() {
        let current = currentFrameCount
        guard current > lastReadFrameCount else { return }

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let framesDir = containerURL.appendingPathComponent("Frames", isDirectory: true)

        for frameIndex in (lastReadFrameCount + 1)...current {
            let frameURL = framesDir.appendingPathComponent("frame_\(frameIndex).jpg")
            guard FileManager.default.fileExists(atPath: frameURL.path) else { continue }

            if let image = loadImage(from: frameURL) {
                onNewFrame?(image)
                try? FileManager.default.removeItem(at: frameURL)
            }
        }

        lastReadFrameCount = current
    }

    private func loadImage(from url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    func cleanupFrames() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let framesDir = containerURL.appendingPathComponent("Frames", isDirectory: true)
        try? FileManager.default.removeItem(at: framesDir)

        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.removeObject(forKey: "currentFrameCount")
        defaults?.removeObject(forKey: "isBroadcasting")
        defaults?.removeObject(forKey: "broadcastStartTime")
        defaults?.synchronize()
    }
}
#endif
