import Foundation
import Network
import OSLog

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected: Bool
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
        self.isConnected = self.monitor.currentPath.status == .satisfied
        self.startMonitoring()
    }

    private func startMonitoring() {
        self.monitor.pathUpdateHandler = { [weak self] path in
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
                let wasConnected = self.isConnected
                self.isConnected = connected
                self.connectionType = type

                if wasConnected, !connected {
                    self.logger.warning("Network disconnected")
                } else if !wasConnected, connected {
                    self.logger.info("Network reconnected via \(type.rawValue)")
                }
            }
        }
        self.monitor.start(queue: self.queue)
    }

    deinit {
        monitor.cancel()
    }
}
