import Foundation
import os.signpost
import OSLog

enum PerformanceMonitor {
    private static let pointsOfInterest = OSLog(
        subsystem: "com.ethanshen.scrollcap",
        category: .pointsOfInterest
    )

    private static let captureLog = OSLog(
        subsystem: "com.ethanshen.scrollcap",
        category: "capture-perf"
    )

    private static let stitchLog = OSLog(
        subsystem: "com.ethanshen.scrollcap",
        category: "stitch-perf"
    )

    private static let exportLog = OSLog(
        subsystem: "com.ethanshen.scrollcap",
        category: "export-perf"
    )

    // MARK: - Capture

    static func beginCapture() -> OSSignpostID {
        let id = OSSignpostID(log: captureLog)
        os_signpost(.begin, log: captureLog, name: "Capture Session", signpostID: id)
        os_signpost(.event, log: pointsOfInterest, name: "Capture Started")
        return id
    }

    static func endCapture(_ id: OSSignpostID, frames: Int) {
        os_signpost(.end, log: captureLog, name: "Capture Session", signpostID: id, "%d frames", frames)
        os_signpost(.event, log: pointsOfInterest, name: "Capture Completed")
    }

    // MARK: - Stitch

    static func beginStitch() -> OSSignpostID {
        let id = OSSignpostID(log: stitchLog)
        os_signpost(.begin, log: stitchLog, name: "Image Stitch", signpostID: id)
        return id
    }

    static func endStitch(_ id: OSSignpostID, resultHeight: Int) {
        os_signpost(.end, log: stitchLog, name: "Image Stitch", signpostID: id, "height=%d", resultHeight)
    }

    // MARK: - Export

    static func beginExport(format: String) -> OSSignpostID {
        let id = OSSignpostID(log: exportLog)
        os_signpost(.begin, log: exportLog, name: "Export", signpostID: id, "%{public}s", format)
        return id
    }

    static func endExport(_ id: OSSignpostID) {
        os_signpost(.end, log: exportLog, name: "Export", signpostID: id)
    }

    // MARK: - Generic Measurement

    static func measure<T>(_ name: StaticString, _ operation: () async throws -> T) async rethrows -> T {
        let id = OSSignpostID(log: captureLog)
        os_signpost(.begin, log: captureLog, name: name, signpostID: id)
        let result = try await operation()
        os_signpost(.end, log: captureLog, name: name, signpostID: id)
        return result
    }

    // MARK: - Memory Tracking

    static func reportMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1_048_576.0
            let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "memory")
            logger.info("Memory usage: \(String(format: "%.1f", usedMB)) MB")

            if usedMB > 500 {
                logger.warning("⚠️ High memory usage: \(String(format: "%.1f", usedMB)) MB")
                AnalyticsManager.shared.track(
                    .error(domain: "memory", code: "high_usage_\(Int(usedMB))MB")
                )
            }
        }
    }
}
