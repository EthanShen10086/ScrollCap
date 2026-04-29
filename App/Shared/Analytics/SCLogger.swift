import Foundation
import OSLog

public enum SCLogger {
    public static let capture = Logger(subsystem: "com.ethanshen.scrollcap", category: "capture")
    public static let stitch = Logger(subsystem: "com.ethanshen.scrollcap", category: "stitch")
    public static let export = Logger(subsystem: "com.ethanshen.scrollcap", category: "export")
    public static let sync = Logger(subsystem: "com.ethanshen.scrollcap", category: "sync")
    public static let payment = Logger(subsystem: "com.ethanshen.scrollcap", category: "payment")
    public static let general = Logger(subsystem: "com.ethanshen.scrollcap", category: "general")
    public static let ocr = Logger(subsystem: "com.ethanshen.scrollcap", category: "ocr")
}

extension Logger {
    func started(_ message: String = "started") {
        self.info("▶️ \(message)")
    }

    func completed(_ message: String = "completed", duration: TimeInterval? = nil) {
        if let duration {
            self.info("✅ \(message) (duration: \(String(format: "%.2f", duration))s)")
        } else {
            self.info("✅ \(message)")
        }
    }

    func failed(_ message: String, error: Error? = nil) {
        if let error {
            self.error("❌ \(message): \(error.localizedDescription)")
        } else {
            self.error("❌ \(message)")
        }
    }
}
