import SwiftUI
import DesignSystem

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        #if os(macOS)
        macOSLayout
        #elseif os(iOS)
        iOSLayout
        #endif
    }

    // MARK: - macOS

    #if os(macOS)
    private var macOSLayout: some View {
        @Bindable var state = appState
        return NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
        } detail: {
            detailContent
        }
    }
    #endif

    // MARK: - iOS

    #if os(iOS)
    private var iOSLayout: some View {
        @Bindable var state = appState
        return Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                NavigationSplitView {
                    sidebarContent
                } detail: {
                    detailContent
                }
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
        @Bindable var state = appState
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
        switch appState.selectedDestination ?? .capture {
        case .capture:
            CaptureView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
