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
                #if os(macOS)
                .onAppear { setupMacOS() }
                #endif
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
