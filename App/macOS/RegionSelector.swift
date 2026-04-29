#if os(macOS)
import SwiftUI
import AppKit
import SharedModels

struct RegionSelectorView: NSViewRepresentable {
    @Binding var selectedRegion: CaptureRegion?
    let onSelectionComplete: (CaptureRegion) -> Void

    func makeNSView(context: Context) -> RegionSelectionNSView {
        let view = RegionSelectionNSView()
        view.onSelectionComplete = { rect in
            let region = CaptureRegion(
                origin: rect.origin,
                size: rect.size,
                scale: NSScreen.main?.backingScaleFactor ?? 2.0
            )
            selectedRegion = region
            onSelectionComplete(region)
        }
        return view
    }

    func updateNSView(_ nsView: RegionSelectionNSView, context: Context) {}
}

class RegionSelectionNSView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    private var selectionStart: NSPoint?
    private var selectionRect: CGRect = .zero
    private var isSelecting = false

    override func mouseDown(with event: NSEvent) {
        selectionStart = convert(event.locationInWindow, from: nil)
        isSelecting = true
        selectionRect = .zero
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = selectionStart else { return }
        let current = convert(event.locationInWindow, from: nil)

        selectionRect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        isSelecting = false
        if selectionRect.width > 10 && selectionRect.height > 10 {
            onSelectionComplete?(selectionRect)
        }
        selectionStart = nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.clear.setFill()
        dirtyRect.fill()

        if isSelecting && selectionRect != .zero {
            NSColor.systemBlue.withAlphaComponent(0.15).setFill()
            let path = NSBezierPath(roundedRect: selectionRect, xRadius: 4, yRadius: 4)
            path.fill()

            NSColor.systemBlue.withAlphaComponent(0.6).setStroke()
            path.lineWidth = 2
            path.setLineDash([6, 3], count: 2, phase: 0)
            path.stroke()
        }
    }
}
#endif
