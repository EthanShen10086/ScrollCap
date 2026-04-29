import SwiftUI

@main
struct ScrollCapApp: App {
    @State private var appState = AppState()
    #if os(macOS)
    @State private var overlayController = OverlayWindowController()
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onAppear {
                    CrashReporter.shared.install()
                    AnalyticsManager.shared.track(.appLaunched)
                    #if os(macOS)
                    setupMacOS()
                    #endif
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(after: .newItem) {
                Button(String(localized: "capture.newScroll")) {
                    startQuickCapture()
                }
                .keyboardShortcut("6", modifiers: [.command, .shift])
            }
        }
        #endif

        #if os(macOS)
        MenuBarExtra("ScrollCap", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
        #endif
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "scrollcap" else { return }
        switch url.host {
        case "capture":
            appState.selectedDestination = .capture
            #if os(macOS)
            startQuickCapture()
            #endif
        default:
            break
        }
    }

    #if os(macOS)
    private func setupMacOS() {
        GlobalShortcutManager.shared.register {
            startQuickCapture()
        }
    }

    private func startQuickCapture() {
        appState.captureState = .selectingRegion
    }
    #endif
}
