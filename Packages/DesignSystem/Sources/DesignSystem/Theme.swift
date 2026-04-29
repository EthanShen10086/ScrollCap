import SwiftUI

public enum SCTheme {
    public enum Colors {
        public static let primary = Color.accentColor
        public static let destructive = Color.red
        public static let success = Color.green

        public static let textPrimary = Color.primary
        public static let textSecondary = Color.secondary

        public static let captureActive = Color.red
        public static let captureReady = Color.blue
        public static let captureDone = Color.green

        public static let cardBackground = Color.secondary.opacity(0.12)
        public static let overlayBackground = Color.black.opacity(0.4)
        public static let subtleSeparator = Color.primary.opacity(0.15)
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
    }

    public enum Typography {
        public static let largeTitle = Font.largeTitle.weight(.bold)
        public static let title = Font.title2.weight(.semibold)
        public static let headline = Font.headline
        public static let body = Font.body
        public static let caption = Font.caption
        public static let monoCaption = Font.system(.caption, design: .monospaced)
    }

    public enum Animation {
        public static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        public static let quick = SwiftUI.Animation.easeInOut(duration: 0.15)
        public static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        public static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }

    public enum IconSize {
        public static let sm: CGFloat = 16
        public static let md: CGFloat = 24
        public static let lg: CGFloat = 32
        public static let xl: CGFloat = 48
    }
}
