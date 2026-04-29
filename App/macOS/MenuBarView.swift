#if os(macOS)
import DesignSystem
import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: SCTheme.Spacing.sm) {
            headerSection

            Divider()

            actionButtons

            Divider()

            statusSection

            Divider()

            Button(String(localized: "menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(SCTheme.Spacing.sm)
        .frame(width: 260)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: "camera.viewfinder")
                .font(.title3)
                .foregroundStyle(.blue)

            Text("nav.scrollcap")
                .font(SCTheme.Typography.headline)

            Spacer()

            Text("menu.version")
                .font(SCTheme.Typography.monoCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, SCTheme.Spacing.xs)
    }

    private var actionButtons: some View {
        VStack(spacing: SCTheme.Spacing.xs) {
            Button {
                startQuickCapture()
            } label: {
                Label("menu.newCapture", systemImage: "scroll")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .keyboardShortcut("n")
            .disabled(appState.isCapturing)

            Button {
                openMainWindow()
            } label: {
                Label("menu.open", systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .keyboardShortcut("o")
        }
        .buttonStyle(.borderless)
    }

    private var statusSection: some View {
        HStack {
            Circle()
                .fill(appState.isCapturing ? SCTheme.Colors.captureActive : .green)
                .frame(width: 8, height: 8)

            Text(appState.isCapturing ? String(localized: "menu.capturing") : String(localized: "menu.ready"))
                .font(SCTheme.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text("menu.captures \(appState.screenshots.count)")
                .font(SCTheme.Typography.monoCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, SCTheme.Spacing.xs)
    }

    private func startQuickCapture() {
        appState.captureState = .selectingRegion
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows
            .first(where: { $0.title.contains("ScrollCap") || $0.isKeyWindow }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
#endif
