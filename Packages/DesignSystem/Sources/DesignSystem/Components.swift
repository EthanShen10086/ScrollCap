import SwiftUI

// MARK: - Capture Button

public struct CaptureButton: View {
    let isCapturing: Bool
    let action: () -> Void
    @State private var pulseScale: CGFloat = 1.0
    @State private var isPressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.userMode) private var userMode

    private var shouldReduceMotion: Bool {
        self.reduceMotion || self.userMode == .elder
    }

    public init(isCapturing: Bool, action: @escaping () -> Void) {
        self.isCapturing = isCapturing
        self.action = action
    }

    public var body: some View {
        Button(action: self.action) {
            ZStack {
                if !self.isCapturing {
                    Circle()
                        .fill(SCTheme.Colors.captureReady.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(self.shouldReduceMotion ? 1.0 : self.pulseScale)
                        .onAppear {
                            guard !self.shouldReduceMotion else { return }
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                self.pulseScale = 1.15
                            }
                        }
                } else {
                    Circle()
                        .fill(SCTheme.Colors.captureActive.opacity(0.2))
                        .frame(width: 88, height: 88)
                        .scaleEffect(self.shouldReduceMotion ? 1.0 : self.pulseScale)
                        .onAppear {
                            guard !self.shouldReduceMotion else { return }
                            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                self.pulseScale = 1.1
                            }
                        }
                }

                Circle()
                    .fill(
                        self.isCapturing
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
                        color: (self.isCapturing ? SCTheme.Colors.captureActive : SCTheme.Colors.brandBlue)
                            .opacity(0.4),
                        radius: 12,
                        y: 4
                    )

                if self.isCapturing {
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
        .accessibilityLabel(self.isCapturing ? Text("a11y.capture.stop") : Text("a11y.capture.start"))
        .accessibilityHint(self.isCapturing ? Text("a11y.capture.stop.hint") : Text("a11y.capture.hint"))
        .accessibilityAddTraits(.isButton)
        .animation(SCTheme.Animation.spring, value: self.isCapturing)
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
        Text(self.text)
            .font(SCTheme.Typography.caption)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, SCTheme.Spacing.sm + 4)
            .padding(.vertical, SCTheme.Spacing.xs + 2)
            .background(self.color.gradient, in: Capsule())
            .shadow(color: self.color.opacity(0.3), radius: 4, y: 2)
            .accessibilityLabel(self.text)
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
        self.content
            .padding(SCTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(self.colorScheme == .dark ? 0.15 : 0.4),
                                        Color.white.opacity(self.colorScheme == .dark ? 0.05 : 0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: self.colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.08),
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.userMode) private var userMode

    private var shouldReduceMotion: Bool {
        self.reduceMotion || self.userMode == .elder
    }

    public init(systemImage: String, title: String, description: String) {
        self.systemImage = systemImage
        self.title = title
        self.description = description
    }

    public var body: some View {
        VStack(spacing: SCTheme.Spacing.lg) {
            self.emptyStateIcon
                .accessibilityHidden(true)

            VStack(spacing: SCTheme.Spacing.sm) {
                Text(self.title)
                    .font(SCTheme.Typography.title)

                Text(self.description)
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
        if self.shouldReduceMotion {
            base
        } else if #available(iOS 18.0, macOS 15.0, *) {
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
        Button(action: self.action) {
            Label(self.title, systemImage: self.systemImage)
                .font(SCTheme.Typography.callout)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .padding(.horizontal, SCTheme.Spacing.md)
                .padding(.vertical, SCTheme.Spacing.sm + 2)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(self.colorScheme == .dark ? 0.1 : 0.3), lineWidth: 0.5)
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
        Button(action: self.action) {
            Label(self.title, systemImage: self.systemImage)
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
        self.content
            .padding(.horizontal, SCTheme.Spacing.lg)
            .padding(.vertical, SCTheme.Spacing.md)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(self.colorScheme == .dark ? 0.1 : 0.25), lineWidth: 0.5)
                    )
                    .shadow(
                        color: self.colorScheme == .dark ? .black.opacity(0.4) : .black.opacity(0.1),
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
        Button(action: self.action) {
            VStack(alignment: .leading, spacing: SCTheme.Spacing.sm) {
                Image(decorative: self.image, scale: 1.0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: SCTheme.CornerRadius.md))

                VStack(alignment: .leading, spacing: 2) {
                    Text(self.title)
                        .font(SCTheme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(self.subtitle)
                        .font(SCTheme.Typography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 4)
            }
            .padding(SCTheme.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                    .fill(self.colorScheme == .dark ? Color.white.opacity(0.05) : Color.white)
                    .shadow(
                        color: self.colorScheme == .dark ? .black.opacity(0.3) : .black.opacity(0.06),
                        radius: self.isHovered ? 16 : 8,
                        y: self.isHovered ? 8 : 4
                    )
            }
            .scaleEffect(self.isHovered ? 1.02 : 1.0)
            .animation(SCTheme.Animation.gentle, value: self.isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            self.isHovered = hovering
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.title)
        .accessibilityHint(self.subtitle)
        .accessibilityAddTraits(.isButton)
    }
}
