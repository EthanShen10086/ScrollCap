import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif

private nonisolated(unsafe) var crashLogPath: UnsafeMutablePointer<CChar>?

@MainActor
final class CrashReporter {
    static let shared = CrashReporter()

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "crash")
    private let crashLogDirectory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.crashLogDirectory = appSupport.appendingPathComponent("ScrollCap/CrashLogs", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.crashLogDirectory, withIntermediateDirectories: true)

        let sentinelPath = self.crashLogDirectory.appendingPathComponent("crash_sentinel").path
        crashLogPath = strdup(sentinelPath)
    }

    func install() {
        NSSetUncaughtExceptionHandler { exception in
            let info = CrashInfo(
                name: exception.name.rawValue,
                reason: exception.reason ?? "Unknown",
                callStack: exception.callStackSymbols,
                timestamp: Date(),
                deviceInfo: DeviceInfo.current
            )
            CrashReporter.writeCrashLog(info)
        }

        self.setupSignalHandlers()
        self.checkForPreviousCrash()
    }

    private func setupSignalHandlers() {
        let signals: [Int32] = [SIGABRT, SIGSEGV, SIGBUS, SIGFPE, SIGILL, SIGTRAP]
        for sig in signals {
            signal(sig) { signalNumber in
                CrashReporter.handleSignalSafe(signalNumber)
            }
        }
    }

    /// Async-signal-safe: only uses write(2) syscall, no allocations
    private static func handleSignalSafe(_ sig: Int32) {
        guard let path = crashLogPath else {
            _exit(sig)
        }
        let fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        if fd >= 0 {
            var sigValue = sig
            withUnsafeBytes(of: &sigValue) { buf in
                _ = write(fd, buf.baseAddress!, buf.count)
            }
            close(fd)
        }
        _exit(sig)
    }

    /// Safe to call from main context — reads sentinel + full crash JSON
    private static func writeCrashLog(_ info: CrashInfo) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ScrollCap/CrashLogs", isDirectory: true)
        let fileURL = dir.appendingPathComponent("crash_\(Int(Date().timeIntervalSince1970)).json")

        if let data = try? JSONEncoder().encode(info) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func checkForPreviousCrash() {
        self.checkSignalSentinel()

        guard let files = try? FileManager.default.contentsOfDirectory(
            at: self.crashLogDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        let crashFiles = files.filter { $0.pathExtension == "json" }
        for file in crashFiles {
            if let data = try? Data(contentsOf: file),
               let info = try? JSONDecoder().decode(CrashInfo.self, from: data) {
                self.logger.error("📋 Previous crash detected: \(info.name) - \(info.reason)")
                AnalyticsManager.shared.track(.crashDetected(name: info.name, reason: info.reason))
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func checkSignalSentinel() {
        let sentinelURL = self.crashLogDirectory.appendingPathComponent("crash_sentinel")
        guard FileManager.default.fileExists(atPath: sentinelURL.path),
              let data = try? Data(contentsOf: sentinelURL),
              data.count >= MemoryLayout<Int32>.size
        else { return }

        let signal = data.withUnsafeBytes { $0.load(as: Int32.self) }
        let signalName = switch signal {
        case SIGABRT: "SIGABRT"
        case SIGSEGV: "SIGSEGV"
        case SIGBUS: "SIGBUS"
        case SIGFPE: "SIGFPE"
        case SIGILL: "SIGILL"
        case SIGTRAP: "SIGTRAP"
        default: "SIGNAL_\(signal)"
        }

        self.logger.error("📋 Previous signal crash: \(signalName)")
        AnalyticsManager.shared.track(.crashDetected(name: signalName, reason: "Signal \(signalName) received"))
        try? FileManager.default.removeItem(at: sentinelURL)
    }
}

// MARK: - Models

struct CrashInfo: Codable {
    let name: String
    let reason: String
    let callStack: [String]
    let timestamp: Date
    let deviceInfo: DeviceInfo
}

struct DeviceInfo: Codable {
    let osVersion: String
    let appVersion: String
    let buildNumber: String
    let deviceModel: String

    static var current: DeviceInfo {
        let osVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        }()

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"

        var model = "Unknown"
        #if os(macOS)
        model = "Mac"
        #elseif os(iOS)
        model = "iPhone/iPad"
        #endif

        return DeviceInfo(
            osVersion: osVersion,
            appVersion: appVersion,
            buildNumber: buildNumber,
            deviceModel: model
        )
    }
}
