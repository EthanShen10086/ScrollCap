import Foundation

final class PaymentConfig: Sendable {
    static let shared = PaymentConfig()

    let serverBaseURL: URL

    private init() {
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "PaymentServerURL") as? String,
           let url = URL(string: urlString) {
            serverBaseURL = url
        } else {
            #if DEBUG
            serverBaseURL = URL(string: "https://localhost:8443")!
            #else
            serverBaseURL = URL(string: "https://api.scrollcap.app")!
            #endif
        }
    }
}

struct PaymentServerResponse: Codable {
    let transactionId: String
    let status: String
}

enum PaymentResult {
    case success(transactionId: String)
    case cancelled
    case failed(Error)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var transactionId: String? {
        if case let .success(id) = self { return id }
        return nil
    }
}

extension PaymentResult: @unchecked Sendable {}
