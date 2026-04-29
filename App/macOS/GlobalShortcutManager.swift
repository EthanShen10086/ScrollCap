#if os(macOS)
import AppKit
import Carbon

@MainActor
final class GlobalShortcutManager {
    static let shared = GlobalShortcutManager()

    private var eventHandler: EventHandlerRef?
    private var onCaptureTriggered: (() -> Void)?

    private init() {}

    func register(onCapture: @escaping () -> Void) {
        self.onCaptureTriggered = onCapture

        var hotKeyRef: EventHotKeyRef?
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let hotKeyID = EventHotKeyID(signature: OSType(0x5343_4150), id: 1) // "SCAP"

        // Cmd+Shift+6
        RegisterEventHotKey(
            UInt32(kVK_ANSI_6),
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

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
