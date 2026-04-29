import SwiftUI

@MainActor
enum HapticManager {
    #if os(iOS)
    static func captureStarted() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func captureStopped() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func captureError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selectionChanged() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    #else
    static func captureStarted() {}
    static func captureStopped() {}
    static func captureError() {}
    static func selectionChanged() {}
    #endif
}
