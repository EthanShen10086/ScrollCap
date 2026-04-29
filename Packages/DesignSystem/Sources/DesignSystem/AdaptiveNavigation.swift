import SwiftUI

public enum NavigationDestination: Hashable, Sendable {
    case capture
    case history
    case settings
}

public struct AdaptiveNavigationContainer<Sidebar: View, Detail: View>: View {
    let sidebar: Sidebar
    let detail: Detail

    public init(
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public var body: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            detail
        }
        #else
        adaptiveIOSLayout
        #endif
    }

    #if os(iOS)
    @ViewBuilder
    private var adaptiveIOSLayout: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                sidebar
            } detail: {
                detail
            }
        } else {
            TabView {
                detail
            }
        }
    }
    #endif
}

// MARK: - Sidebar Item

public struct SidebarItem: View {
    let title: String
    let systemImage: String
    let destination: NavigationDestination

    public init(title: String, systemImage: String, destination: NavigationDestination) {
        self.title = title
        self.systemImage = systemImage
        self.destination = destination
    }

    public var body: some View {
        Label(title, systemImage: systemImage)
    }
}
