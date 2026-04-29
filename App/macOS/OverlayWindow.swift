#if os(macOS)
import AppKit
import SwiftUI
import SharedModels

@MainActor
final class OverlayWindowController {
    private var overlayWindow: NSWindow?
    private var onRegionSelected: ((CaptureRegion) -> Void)?

    func showRegionSelector(onSelected: @escaping (CaptureRegion) -> Void) {
        onRegionSelected = onSelected

        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )

        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        window.ignoresMouseEvents = false
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(
            rootView: RegionSelectorView(selectedRegion: .constant(nil)) { region in
                onSelected(region)
                self.dismiss()
            }
        )
        hostingView.frame = screen.frame
        window.contentView = hostingView

        overlayWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
    }
}
#endif
