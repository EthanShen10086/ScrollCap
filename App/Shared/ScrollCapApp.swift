import DesignSystem
import OSLog
import SwiftUI
#if os(iOS)
import UIKit
#endif

@main
struct ScrollCapApp: App {
    @State private var appState = AppState()
    #if os(macOS)
    @State private var overlayController = OverlayWindowController()
    #endif

    init() {
        CrashReporter.shared.install()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(self.appState)
                .environment(\.userMode, self.appState.userMode)
                .applyUserMode(self.appState.userMode)
                .onAppear {
                    Task(priority: .utility) {
                        await MainActor.run {
                            AnalyticsManager.shared.track(.appLaunched)
                        }
                    }
                    if self.appState.iCloudSyncEnabled {
                        Task(priority: .utility) {
                            await ICloudSyncManager.shared.startMonitoring()
                        }
                    }
                    #if os(macOS)
                    self.setupMacOS()
                    #endif
                }
                .onOpenURL { url in
                    self.handleDeepLink(url)
                }
                .task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(60))
                        self.appState.checkUsageTime()
                        PerformanceMonitor.reportMemoryUsage()
                    }
                }
            #if os(iOS)
                .onReceive(NotificationCenter.default
                    .publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                        SCLogger.app.warning("Memory warning received, clearing caches")
                        self.appState.handleMemoryWarning()
                }
            #endif
        }
        #if os(macOS)
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
        .commands {
            CommandGroup(after: .newItem) {
                Button(String(localized: "capture.newScroll")) {
                    self.startQuickCapture()
                }
                .keyboardShortcut("6", modifiers: [.command, .shift])
            }
        }
        #endif

        #if os(macOS)
        MenuBarExtra("ScrollCap", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environment(self.appState)
                .environment(\.userMode, self.appState.userMode)
                .applyUserMode(self.appState.userMode)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(self.appState)
                .environment(\.userMode, self.appState.userMode)
                .applyUserMode(self.appState.userMode)
        }
        #endif
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "scrollcap" else { return }
        switch url.host {
        case "capture":
            self.appState.selectedDestination = .capture
            #if os(macOS)
            self.startQuickCapture()
            #endif
        case "payment":
            guard !self.appState.shouldHidePayment else { return }
            Task {
                _ = await ThirdPartyPaymentService.shared.handlePaymentCallback(url: url)
            }
        default:
            break
        }
    }

    #if os(macOS)
    private func setupMacOS() {
        GlobalShortcutManager.shared.register {
            self.startQuickCapture()
        }
    }

    private func startQuickCapture() {
        self.appState.captureState = .selectingRegion
    }
    #endif
}
