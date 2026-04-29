import Foundation
import Network
import OSLog

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected = true
    private(set) var connectionType: ConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.ethanshen.scrollcap.network-monitor")
    private let logger = Logger(subsystem: "com.ethanshen.scrollcap", category: "network")

    enum ConnectionType: String {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let type: ConnectionType = if path.usesInterfaceType(.wifi) {
                .wifi
            } else if path.usesInterfaceType(.cellular) {
                .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                .wiredEthernet
            } else {
                .unknown
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasConnected = isConnected
                isConnected = connected
                connectionType = type

                if wasConnected, !connected {
                    logger.warning("Network disconnected")
                } else if !wasConnected, connected {
                    logger.info("Network reconnected via \(type.rawValue)")
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
