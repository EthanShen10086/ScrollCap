import SwiftUI

public protocol PlatformMetricsProvider: Sendable {
    var sidebarWidth: CGFloat { get }
    var minContentWidth: CGFloat { get }
    var toolbarHeight: CGFloat { get }
    var defaultPadding: CGFloat { get }
    var capturePreviewMaxWidth: CGFloat { get }
}

#if os(macOS)
public struct MacMetrics: PlatformMetricsProvider {
    public let sidebarWidth: CGFloat = 220
    public let minContentWidth: CGFloat = 600
    public let toolbarHeight: CGFloat = 52
    public let defaultPadding: CGFloat = 20
    public let capturePreviewMaxWidth: CGFloat = 800

    public init() {}
}
#endif

#if os(iOS)
public struct PhoneMetrics: PlatformMetricsProvider {
    public let sidebarWidth: CGFloat = 0
    public let minContentWidth: CGFloat = 320
    public let toolbarHeight: CGFloat = 44
    public let defaultPadding: CGFloat = 16
    public let capturePreviewMaxWidth: CGFloat = .infinity

    public init() {}
}

public struct PadMetrics: PlatformMetricsProvider {
    public let sidebarWidth: CGFloat = 320
    public let minContentWidth: CGFloat = 500
    public let toolbarHeight: CGFloat = 50
    public let defaultPadding: CGFloat = 20
    public let capturePreviewMaxWidth: CGFloat = 700

    public init() {}
}
#endif

public extension EnvironmentValues {
    @Entry var platformMetrics: any PlatformMetricsProvider = {
        #if os(macOS)
        return MacMetrics()
        #else
        return PhoneMetrics()
        #endif
    }()
}
