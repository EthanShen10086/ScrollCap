import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class CrashReporter {
    static let shared = CrashReporter()

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "crash")
    private let crashLogDirectory: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.crashLogDirectory = appSupport.appendingPathComponent("ScrollCap/CrashLogs", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.crashLogDirectory, withIntermediateDirectories: true)
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
        signal(SIGABRT) { _ in CrashReporter.handleSignal("SIGABRT") }
        signal(SIGSEGV) { _ in CrashReporter.handleSignal("SIGSEGV") }
        signal(SIGBUS) { _ in CrashReporter.handleSignal("SIGBUS") }
        signal(SIGFPE) { _ in CrashReporter.handleSignal("SIGFPE") }
        signal(SIGILL) { _ in CrashReporter.handleSignal("SIGILL") }
    }

    private static func handleSignal(_ signalName: String) {
        let info = CrashInfo(
            name: signalName,
            reason: "Signal \(signalName) received",
            callStack: Thread.callStackSymbols,
            timestamp: Date(),
            deviceInfo: DeviceInfo.current
        )
        self.writeCrashLog(info)
    }

    private static func writeCrashLog(_ info: CrashInfo) {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ScrollCap/CrashLogs", isDirectory: true)
        let fileURL = dir.appendingPathComponent("crash_\(Int(Date().timeIntervalSince1970)).json")

        if let data = try? JSONEncoder().encode(info) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func checkForPreviousCrash() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: crashLogDirectory,
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
