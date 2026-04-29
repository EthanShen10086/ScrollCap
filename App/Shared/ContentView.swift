import DesignSystem
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        #if os(macOS)
        self.macOSLayout
        #elseif os(iOS)
        self.iOSLayout
        #endif
    }

    // MARK: - macOS

    #if os(macOS)
    private var macOSLayout: some View {
        @Bindable var state = self.appState
        return NavigationSplitView {
            self.sidebarContent
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            self.detailContent
        }
    }
    #endif

    // MARK: - iOS

    #if os(iOS)
    private var iOSLayout: some View {
        @Bindable var state = self.appState
        return Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                NavigationSplitView {
                    self.sidebarContent
                } detail: {
                    self.detailContent
                }
                .environment(\.platformMetrics, PadMetrics())
            } else {
                TabView(selection: $state.selectedDestination) {
                    NavigationStack {
                        CaptureView()
                    }
                    .tabItem {
                        Label("nav.capture", systemImage: "camera.viewfinder")
                    }
                    .tag(Optional(AppDestination.capture))

                    NavigationStack {
                        HistoryView()
                    }
                    .tabItem {
                        Label("nav.history", systemImage: "clock.arrow.circlepath")
                    }
                    .tag(Optional(AppDestination.history))

                    NavigationStack {
                        SettingsView()
                    }
                    .tabItem {
                        Label("nav.settings", systemImage: "gear")
                    }
                    .tag(Optional(AppDestination.settings))
                }
            }
        }
    }
    #endif

    // MARK: - Shared Components

    private var sidebarContent: some View {
        @Bindable var state = self.appState
        return List(selection: $state.selectedDestination) {
            ForEach([AppDestination.capture, .history, .settings]) { dest in
                Label(dest.title, systemImage: dest.systemImage)
                    .tag(dest)
            }
        }
        .navigationTitle("nav.scrollcap")
    }

    @ViewBuilder
    private var detailContent: some View {
        switch self.appState.selectedDestination ?? .capture {
        case .capture:
            CaptureView()
                .onAppear { AnalyticsManager.shared.track(.screenViewed(name: "capture")) }
        case .history:
            HistoryView()
                .onAppear { AnalyticsManager.shared.track(.screenViewed(name: "history")) }
        case .settings:
            SettingsView()
                .onAppear { AnalyticsManager.shared.track(.screenViewed(name: "settings")) }
        }
    }
}
