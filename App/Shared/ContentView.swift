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
                TabView(selection: Bindable(appState).selectedDestination) {
                    Tab("Capture", systemImage: "camera.viewfinder", value: AppDestination.capture) {
                        NavigationStack {
                            CaptureView()
                        }
                    }
                    Tab("History", systemImage: "clock.arrow.circlepath", value: AppDestination.history) {
                        NavigationStack {
                            HistoryView()
                        }
                    }
                    Tab("Settings", systemImage: "gear", value: AppDestination.settings) {
                        NavigationStack {
                            SettingsView()
                        }
                    }
                }
            }
        }
    }
    #endif

    // MARK: - Shared Components

    private var sidebarContent: some View {
        List(selection: Bindable(appState).selectedDestination) {
            ForEach([AppDestination.capture, .history, .settings]) { dest in
                Label(dest.title, systemImage: dest.systemImage)
                    .tag(dest)
            }
        }
        .navigationTitle("ScrollCap")
    }

    @ViewBuilder
    private var detailContent: some View {
        switch appState.selectedDestination {
        case .capture:
            CaptureView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        }
    }
}
