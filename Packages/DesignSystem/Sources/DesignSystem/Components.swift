import SwiftUI

// MARK: - Capture Button

public struct CaptureButton: View {
    let isCapturing: Bool
    let action: () -> Void

    public init(isCapturing: Bool, action: @escaping () -> Void) {
        self.isCapturing = isCapturing
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isCapturing ? SCTheme.Colors.captureActive : SCTheme.Colors.captureReady)
                    .frame(width: 64, height: 64)

                if isCapturing {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 22, height: 22)
                } else {
                    Circle()
                        .fill(.white)
                        .frame(width: 28, height: 28)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(SCTheme.Animation.spring, value: isCapturing)
    }
}

// MARK: - Status Pill

public struct StatusPill: View {
    let text: String
    let color: Color

    public init(_ text: String, color: Color = SCTheme.Colors.primary) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(SCTheme.Typography.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, SCTheme.Spacing.sm)
            .padding(.vertical, SCTheme.Spacing.xs)
            .background(color, in: Capsule())
    }
}

// MARK: - Glass Card

public struct GlassCard<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SCTheme.Spacing.md)
            .adaptiveGlass(cornerRadius: SCTheme.CornerRadius.lg)
    }
}

// MARK: - Empty State

public struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let description: String

    public init(systemImage: String, title: String, description: String) {
        self.systemImage = systemImage
        self.title = title
        self.description = description
    }

    public var body: some View {
        VStack(spacing: SCTheme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(SCTheme.Typography.title)

            Text(description)
                .font(SCTheme.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(SCTheme.Spacing.xl)
    }
}
