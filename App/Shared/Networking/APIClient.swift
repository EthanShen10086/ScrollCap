import Foundation
import OSLog

actor APIClient {
    static let shared = APIClient()

    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "api")
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: config)
    }()

    struct RequestConfig {
        var maxRetries: Int = 3
        var retryDelay: TimeInterval = 1.0
        var retryBackoffMultiplier: Double = 2.0
        var retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]

        static let `default` = RequestConfig()
        static let noRetry = RequestConfig(maxRetries: 0)
    }

    // MARK: - Core Request

    func request<T: Decodable>(
        _ type: T.Type,
        url: URL,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        headers: [String: String]? = nil,
        config: RequestConfig = .default
    ) async throws -> T {
        try await checkConnectivity()

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("ScrollCap/\(appVersion)", forHTTPHeaderField: "User-Agent")

        headers?.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        return try await executeWithRetry(urlRequest, type: type, config: config)
    }

    func post<T: Decodable>(
        _ type: T.Type,
        url: URL,
        body: any Encodable,
        config: RequestConfig = .default
    ) async throws -> T {
        try await request(type, url: url, method: .post, body: body, config: config)
    }

    // MARK: - Fire & Forget (for analytics uploads, etc.)

    func send(
        url: URL,
        method: HTTPMethod = .post,
        body: (any Encodable)? = nil
    ) async {
        do {
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = method.rawValue
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

            if let body {
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            }

            _ = try await session.data(for: urlRequest)
        } catch {
            logger.warning("Fire-and-forget request failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Retry Logic

    private func executeWithRetry<T: Decodable>(
        _ request: URLRequest,
        type: T.Type,
        config: RequestConfig,
        attempt: Int = 0
    ) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            return try processResponse(
                data: data,
                response: response,
                type: type,
                request: request,
                config: config,
                attempt: attempt
            )
        } catch let error as SCError {
            throw error
        } catch is DecodingError {
            throw SCError.network(.decodingFailed)
        } catch let error as URLError {
            return try await handleURLError(error, request: request, type: type, config: config, attempt: attempt)
        } catch {
            throw SCError.generic(error.localizedDescription)
        }
    }

    private func processResponse<T: Decodable>(
        data: Data,
        response: URLResponse,
        type: T.Type,
        request: URLRequest,
        config: RequestConfig,
        attempt: Int
    ) async throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SCError.network(.serverError)
        }

        if 200 ... 299 ~= httpResponse.statusCode {
            return try decoder.decode(T.self, from: data)
        }

        if httpResponse.statusCode == 401 {
            throw SCError.network(.unauthorized)
        }

        if config.retryableStatusCodes.contains(httpResponse.statusCode), attempt < config.maxRetries {
            try await retryDelay(config: config, attempt: attempt)
            return try await executeWithRetry(request, type: type, config: config, attempt: attempt + 1)
        }

        throw SCError.network(.serverError)
    }

    private func handleURLError<T: Decodable>(
        _ error: URLError,
        request: URLRequest,
        type: T.Type,
        config: RequestConfig,
        attempt: Int
    ) async throws -> T {
        if error.code == .timedOut, attempt < config.maxRetries {
            try await retryDelay(config: config, attempt: attempt)
            return try await executeWithRetry(request, type: type, config: config, attempt: attempt + 1)
        }
        if error.code == .timedOut { throw SCError.network(.timeout) }
        if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
            throw SCError.network(.offline)
        }
        throw SCError.network(.serverError)
    }

    private func retryDelay(config: RequestConfig, attempt: Int) async throws {
        let delay = config.retryDelay * pow(config.retryBackoffMultiplier, Double(attempt))
        logger.info("Retry \(attempt + 1)/\(config.maxRetries) after \(delay)s")
        try await Task.sleep(for: .seconds(delay))
    }

    // MARK: - Connectivity Check

    private func checkConnectivity() async throws {
        let connected = await MainActor.run { NetworkMonitor.shared.isConnected }
        if !connected {
            throw SCError.network(.offline)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - Type Erasure for Encodable

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeClosure = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
