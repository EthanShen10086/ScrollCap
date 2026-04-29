import SwiftUI

public struct AdaptiveGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isEnabled: Bool

    public init(cornerRadius: CGFloat = 16, isEnabled: Bool = true) {
        self.cornerRadius = cornerRadius
        self.isEnabled = isEnabled
    }

    public func body(content: Content) -> some View {
        if isEnabled {
            glassContent(content)
        } else {
            content
        }
    }

    @ViewBuilder
    private func glassContent(_ content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
    }
}

public struct ClearGlassModifier: ViewModifier {
    let cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            content.glassEffect(.clear, in: .rect(cornerRadius: cornerRadius))
        } else {
            content
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

public struct CircularGlassModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        if #available(iOS 26, macOS 26, *) {
            content.glassEffect(.regular, in: .circle)
        } else {
            content
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
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
