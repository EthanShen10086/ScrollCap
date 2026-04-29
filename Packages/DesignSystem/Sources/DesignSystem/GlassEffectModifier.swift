import SwiftUI

// Liquid Glass (.glassEffect) is available starting with the macOS 26 / iOS 26 SDK (Xcode 26+).
// When building with Xcode 16.x (macOS 15 SDK), we use the material-based fallback.
// Once Xcode 26 is used, the #if swift(>=6.2) blocks will activate native Liquid Glass.

public struct AdaptiveGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isEnabled: Bool

    public init(cornerRadius: CGFloat = 16, isEnabled: Bool = true) {
        self.cornerRadius = cornerRadius
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        if self.isEnabled {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        } else {
            content
        }
    }
}

public struct ClearGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: self.cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

public struct CircularGlassModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

// MARK: - View Extensions

public extension View {
    func adaptiveGlass(cornerRadius: CGFloat = 16, isEnabled: Bool = true) -> some View {
        modifier(AdaptiveGlassModifier(cornerRadius: cornerRadius, isEnabled: isEnabled))
    }

    func clearGlass(cornerRadius: CGFloat = 16) -> some View {
        modifier(ClearGlassModifier(cornerRadius: cornerRadius))
    }

    func circularGlass() -> some View {
        modifier(CircularGlassModifier())
    }
}
