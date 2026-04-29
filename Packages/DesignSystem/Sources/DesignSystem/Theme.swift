import SwiftUI

public enum SCTheme {
    public enum Colors {
        public static let primary = Color.accentColor
        public static let destructive = Color.red
        public static let success = Color.green

        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary

        public static let captureActive = Color.red
        public static let captureReady = Color(red: 0.0, green: 0.47, blue: 0.98)
        public static let captureDone = Color.green

        public static let cardBackground = Color.secondary.opacity(0.12)
        public static let overlayBackground = Color.black.opacity(0.4)
        public static let subtleSeparator = Color.primary.opacity(0.15)

        public static let brandBlue = Color(red: 0.0, green: 0.47, blue: 0.98)
        public static let brandPurple = Color(red: 0.42, green: 0.36, blue: 0.91)
        public static let brandGradientStart = Color(red: 0.0, green: 0.47, blue: 0.98)
        public static let brandGradientEnd = Color(red: 0.42, green: 0.36, blue: 0.91)
    }

    public enum Gradients {
        public static let brand = LinearGradient(
            colors: [Colors.brandBlue, Colors.brandPurple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let captureGlow = RadialGradient(
            colors: [Colors.captureActive.opacity(0.4), Colors.captureActive.opacity(0)],
            center: .center,
            startRadius: 30,
            endRadius: 80
        )

        public static let cardHighlight = LinearGradient(
            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public enum Shadows {
        public static func card(_ scheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            scheme == .dark
                ? (Color.black.opacity(0.3), 12, 6)
                : (Color.black.opacity(0.08), 8, 4)
        }

        public static func elevated(_ scheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            scheme == .dark
                ? (Color.black.opacity(0.5), 20, 10)
                : (Color.black.opacity(0.12), 16, 8)
        }

        public static func floating(_ scheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            scheme == .dark
                ? (Color.black.opacity(0.6), 30, 15)
                : (Color.black.opacity(0.15), 24, 12)
        }
    }

    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    public enum CornerRadius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    public enum Typography {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title2.weight(.semibold)
        public static let title3 = Font.title3.weight(.semibold)
        public static let headline = Font.headline
        public static let body = Font.body
        public static let callout = Font.callout
        public static let caption = Font.caption
        public static let caption2 = Font.caption2
        public static let monoCaption = Font.system(.caption, design: .monospaced)
    }

    public enum Animation {
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        public static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        public static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.85)
        public static let snappy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }

    public enum IconSize {
        public static let sm: CGFloat = 16
        public static let md: CGFloat = 24
        public static let lg: CGFloat = 32
        public static let xl: CGFloat = 48
        public static let xxl: CGFloat = 64
    }
}
