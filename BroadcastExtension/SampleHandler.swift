import CoreMedia
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    private let appGroupID = "group.com.scrollcap.shared"
    private var frameCount = 0

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        frameCount = 0
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(true, forKey: "isBroadcasting")
        defaults?.set(Date().timeIntervalSince1970, forKey: "broadcastStartTime")
        defaults?.synchronize()
    }

    override func broadcastPaused() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(true, forKey: "isBroadcastPaused")
        defaults?.synchronize()
    }

    override func broadcastResumed() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(false, forKey: "isBroadcastPaused")
        defaults?.synchronize()
    }

    override func broadcastFinished() {
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(false, forKey: "isBroadcasting")
        defaults?.set(frameCount, forKey: "totalFrameCount")
        defaults?.synchronize()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            processVideoFrame(sampleBuffer)
        case .audioApp, .audioMic:
            break
        @unknown default:
            break
        }
    }

    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        frameCount += 1

        // Write frame data to shared container for the main app to process
        // Using UserDefaults for frame count signaling; actual frame data
        // transfers via shared container directory for performance
        let defaults = UserDefaults(suiteName: appGroupID)
        defaults?.set(frameCount, forKey: "currentFrameCount")

        if frameCount % 3 == 0 { // Sample every 3rd frame to reduce processing load
            writeFrameToSharedContainer(imageBuffer)
        }
    }

    private func writeFrameToSharedContainer(_ imageBuffer: CVImageBuffer) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let framesDir = containerURL.appendingPathComponent("Frames", isDirectory: true)
        try? FileManager.default.createDirectory(at: framesDir, withIntermediateDirectories: true)

        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

        let frameURL = framesDir.appendingPathComponent("frame_\(frameCount).jpg")
        guard let destination = CGImageDestinationCreateWithURL(
            frameURL as CFURL,
            "public.jpeg" as CFString,
            1,
            nil
        ) else { return }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.7,
        ]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
    }
}
