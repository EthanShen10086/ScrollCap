import SwiftUI

// MARK: - Capture Button

public struct CaptureButton: View {
    let isCapturing: Bool
    let action: () -> Void
    @State private var pulseScale: CGFloat = 1.0
    @State private var isPressed = false

    public init(isCapturing: Bool, action: @escaping () -> Void) {
        self.isCapturing = isCapturing
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                if !isCapturing {
                    Circle()
                        .fill(SCTheme.Colors.captureReady.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseScale = 1.15
                            }
                        }
                } else {
                    Circle()
                        .fill(SCTheme.Colors.captureActive.opacity(0.2))
                        .frame(width: 88, height: 88)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                pulseScale = 1.1
                            }
                        }
                }

                Circle()
                    .fill(
                        isCapturing
                            ? LinearGradient(
                                colors: [SCTheme.Colors.captureActive, SCTheme.Colors.captureActive.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [SCTheme.Colors.brandBlue, SCTheme.Colors.brandPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(
                        color: (isCapturing ? SCTheme.Colors.captureActive : SCTheme.Colors.brandBlue).opacity(0.4),
                        radius: 12,
                        y: 4
                    )

                if isCapturing {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.white)
                        .frame(width: 22, height: 22)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .fill(.white)
                        .frame(width: 26, height: 26)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(isCapturing ? Text("a11y.capture.stop") : Text("a11y.capture.start"))
        .accessibilityHint(isCapturing ? Text("a11y.capture.stop.hint") : Text("a11y.capture.hint"))
        .accessibilityAddTraits(.isButton)
        .animation(SCTheme.Animation.spring, value: isCapturing)
    }
}

// MARK: - Scale Button Style

public struct ScaleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(SCTheme.Animation.snappy, value: configuration.isPressed)
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
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, SCTheme.Spacing.sm + 4)
            .padding(.vertical, SCTheme.Spacing.xs + 2)
            .background(color.gradient, in: Capsule())
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Glass Card

public struct GlassCard<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SCTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
                        radius: 12, y: 6
                    )
            }
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
        VStack(spacing: SCTheme.Spacing.lg) {
            emptyStateIcon
                .accessibilityHidden(true)

            VStack(spacing: SCTheme.Spacing.sm) {
                Text(title)
                    .font(SCTheme.Typography.title)

                Text(description)
                    .font(SCTheme.Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .padding(SCTheme.Spacing.xl)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var emptyStateIcon: some View {
        let base = Image(systemName: systemImage)
            .font(.system(size: 56, weight: .light))
            .foregroundStyle(SCTheme.Gradients.brand)
        if #available(iOS 18.0, macOS 15.0, *) {
            base.symbolEffect(.bounce, options: .repeating.speed(0.3))
        } else {
            base
        }
    }
}

// MARK: - Glass Button

public struct GlassButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(SCTheme.Typography.callout)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .padding(.horizontal, SCTheme.Spacing.md)
                .padding(.vertical, SCTheme.Spacing.sm + 2)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 0.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Branded Glass Button (Accent)

public struct BrandedButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(SCTheme.Typography.callout)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, SCTheme.Spacing.md + 4)
                .padding(.vertical, SCTheme.Spacing.sm + 4)
                .background(SCTheme.Gradients.brand, in: Capsule())
                .shadow(color: SCTheme.Colors.brandBlue.opacity(0.3), radius: 8, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Floating Action Bar

public struct FloatingActionBar<Content: View>: View {
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, SCTheme.Spacing.lg)
            .padding(.vertical, SCTheme.Spacing.md)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(colorScheme == .dark ? 0.1 : 0.25), lineWidth: 0.5)
                    )
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.1),
                        radius: 20, y: 8
                    )
            }
    }
}

// MARK: - Screenshot Card (Enhanced)

public struct ScreenshotCard: View {
    let image: CGImage
    let title: String
    let subtitle: String
    let action: () -> Void
    @State private var isHovered = false
    @Environment(\.colorScheme) private var colorScheme

    public init(image: CGImage, title: String, subtitle: String, action: @escaping () -> Void) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Image(decorative: image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SCTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(subtitle)
                        .font(SCTheme.Typography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
            }
            .padding(SCTheme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
                        radius: isHovered ? 16 : 8,
                        y: isHovered ? 8 : 4
                    )
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(SCTheme.Animation.gentle, value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
    }
}
