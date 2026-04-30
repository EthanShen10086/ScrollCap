#if os(macOS)
import AppKit
import Carbon

@MainActor
final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    private var eventHandler: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var onCaptureTriggered: (() -> Void)?

    private init() {}

    deinit {
        unregister()
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        self.onCaptureTriggered = nil
    }

    func register(onCapture: @escaping () -> Void) {
        self.unregister()
        self.onCaptureTriggered = onCapture

        var newHotKeyRef: EventHotKeyRef?
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let hotKeyID = EventHotKeyID(signature: OSType(0x5343_4150), id: 1) // "SCAP"

        // Cmd+Shift+6
        RegisterEventHotKey(
            UInt32(kVK_ANSI_6),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &newHotKeyRef
        )
        self.hotKeyRef = newHotKeyRef

        var handlerRef: EventHandlerRef?
        let callback: EventHandlerUPP = { _, _, userData -> OSStatus in
            guard let userData else { return noErr }
            let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()

            Task { @MainActor in
                manager.onCaptureTriggered?()
            }

            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            selfPtr,
            &handlerRef
        )
        self.eventHandler = handlerRef
    }
}
#endif
