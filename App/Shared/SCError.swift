import Foundation
import OSLog

enum SCError: Error, LocalizedError, Identifiable {
    case capture(CaptureFailure)
    case stitch(StitchFailure)
    case export(ExportFailure)
    case store(StoreFailure)
    case network(NetworkFailure)
    case ocr(OCRFailure)
    case sync(SyncFailure)
    case generic(String)

    var id: String {
        localizedDescription
    }

    enum CaptureFailure: String {
        case permissionDenied
        case recordingFailed
        case noFrames
        case regionInvalid
    }

    enum StitchFailure: String {
        case alignmentFailed
        case insufficientFrames
        case imageTooLarge
    }

    enum ExportFailure: String {
        case encodingFailed
        case saveCancelled
        case fileWriteFailed
        case unsupportedFormat
    }

    enum StoreFailure: String {
        case verificationFailed
        case purchaseFailed
        case productsUnavailable
        case networkError
    }

    enum NetworkFailure: String {
        case offline
        case timeout
        case serverError
        case decodingFailed
        case unauthorized
    }

    enum OCRFailure: String {
        case recognitionFailed
        case noTextFound
        case imageInvalid
    }

    enum SyncFailure: String {
        case containerUnavailable
        case uploadFailed
        case downloadFailed
        case conflictDetected
    }

    var errorDescription: String? {
        switch self {
        case let .capture(failure): "Capture error: \(failure.rawValue)"
        case let .stitch(failure): "Stitch error: \(failure.rawValue)"
        case let .export(failure): "Export error: \(failure.rawValue)"
        case let .store(failure): "Payment error: \(failure.rawValue)"
        case let .network(failure): "Network error: \(failure.rawValue)"
        case let .ocr(failure): "OCR error: \(failure.rawValue)"
        case let .sync(failure): "Sync error: \(failure.rawValue)"
        case let .generic(msg): msg
        }
    }

    var userMessage: String {
        switch self {
        case let .capture(failure):
            switch failure {
            case .permissionDenied: String(localized: "error.capture.permission")
            case .recordingFailed: String(localized: "error.capture.recording")
            case .noFrames: String(localized: "error.capture.noFrames")
            case .regionInvalid: String(localized: "error.capture.region")
            }
        case let .stitch(failure):
            switch failure {
            case .alignmentFailed: String(localized: "error.stitch.alignment")
            case .insufficientFrames: String(localized: "error.stitch.frames")
            case .imageTooLarge: String(localized: "error.stitch.tooLarge")
            }
        case let .export(failure):
            switch failure {
            case .encodingFailed: String(localized: "error.export.encoding")
            case .saveCancelled: String(localized: "error.export.cancelled")
            case .fileWriteFailed: String(localized: "error.export.write")
            case .unsupportedFormat: String(localized: "error.export.format")
            }
        case .store: String(localized: "error.store.generic")
        case let .network(failure):
            switch failure {
            case .offline: String(localized: "error.network.offline")
            case .timeout: String(localized: "error.network.timeout")
            case .serverError: String(localized: "error.network.server")
            case .decodingFailed: String(localized: "error.network.decode")
            case .unauthorized: String(localized: "error.network.auth")
            }
        case .ocr: String(localized: "error.ocr.generic")
        case .sync: String(localized: "error.sync.generic")
        case let .generic(msg): msg
        }
    }

    var analyticsEvent: AnalyticsEvent {
        switch self {
        case let .capture(failure): .error(domain: "capture", code: failure.rawValue)
        case let .stitch(failure): .error(domain: "stitch", code: failure.rawValue)
        case let .export(failure): .error(domain: "export", code: failure.rawValue)
        case let .store(failure): .error(domain: "store", code: failure.rawValue)
        case let .network(failure): .error(domain: "network", code: failure.rawValue)
        case let .ocr(failure): .error(domain: "ocr", code: failure.rawValue)
        case let .sync(failure): .error(domain: "sync", code: failure.rawValue)
        case let .generic(msg): .error(domain: "generic", code: msg)
        }
    }
}

@MainActor
@Observable
final class ErrorPresenter {
    static let shared = ErrorPresenter()

    private(set) var currentError: SCError?
    private(set) var isPresented = false

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "error")

    private init() {}

    func present(_ error: SCError) {
        currentError = error
        isPresented = true
        logger.error("\(error.localizedDescription)")
        AnalyticsManager.shared.track(error.analyticsEvent)
    }

    func present(_ error: Error) {
        if let scError = error as? SCError {
            present(scError)
        } else {
            present(.generic(error.localizedDescription))
        }
    }

    func dismiss() {
        isPresented = false
        currentError = nil
    }
}
