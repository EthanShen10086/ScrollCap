import SwiftUI

// MARK: - User Mode

public enum UserMode: String, CaseIterable, Identifiable, Sendable {
    case standard
    case minor
    case elder

    public var id: String {
        rawValue
    }

    public var displayName: LocalizedStringKey {
        switch self {
        case .standard: "mode.standard"
        case .minor: "mode.minor"
        case .elder: "mode.elder"
        }
    }

    public var icon: String {
        switch self {
        case .standard: "person"
        case .minor: "figure.child"
        case .elder: "figure.walk"
        }
    }

    public var description: LocalizedStringKey {
        switch self {
        case .standard: "mode.standard.desc"
        case .minor: "mode.minor.desc"
        case .elder: "mode.elder.desc"
        }
    }
}

public extension EnvironmentValues {
    @Entry var userMode: UserMode = .standard
}

// MARK: - User Mode Adaptive Modifier

public struct UserModeAdaptiveModifier: ViewModifier {
    let mode: UserMode

    public init(mode: UserMode) {
        self.mode = mode
    }

    public func body(content: Content) -> some View {
        switch mode {
        case .standard:
            content
                .environment(\.userMode, .standard)

        case .minor:
            content
                .environment(\.userMode, .minor)

        case .elder:
            content
                .environment(\.userMode, .elder)
                .dynamicTypeSize(.xxxLarge)
        }
    }
}

public extension View {
    func applyUserMode(_ mode: UserMode) -> some View {
        modifier(UserModeAdaptiveModifier(mode: mode))
    }
}

// MARK: - Elder Mode Large Button Style

public struct ElderButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(minHeight: 56)
            .background(
                RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                    .fill(Color.accentColor.opacity(configuration.isPressed ? 0.2 : 0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Elder-Friendly Capture Button

public struct ElderCaptureButton: View {
    let isCapturing: Bool
    let action: () -> Void

    public init(isCapturing: Bool, action: @escaping () -> Void) {
        self.isCapturing = isCapturing
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isCapturing
                                ? AnyShapeStyle(Color.red)
                                : AnyShapeStyle(LinearGradient(
                                    colors: [SCTheme.Colors.brandBlue, SCTheme.Colors.brandPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )
                        .frame(width: 88, height: 88)
                        .shadow(
                            color: (isCapturing ? Color.red : SCTheme.Colors.brandBlue).opacity(0.4),
                            radius: 12,
                            y: 4
                        )

                    if isCapturing {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 34, height: 34)
                    }
                }

                Text(isCapturing ? "elder.stop" : "elder.capture")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCapturing ? Text("a11y.elder.stop") : Text("a11y.elder.capture"))
        .accessibilityHint(Text("a11y.elder.hint"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Minor Mode Usage Timer View

public struct UsageTimerBanner: View {
    let minutesUsed: Int
    let limitMinutes: Int
    let onDismiss: () -> Void

    public init(minutesUsed: Int, limitMinutes: Int, onDismiss: @escaping () -> Void) {
        self.minutesUsed = minutesUsed
        self.limitMinutes = limitMinutes
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(spacing: SCTheme.Spacing.md) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.title3)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("minor.timeWarning")
                    .font(.subheadline.weight(.semibold))
                Text("minor.timeUsed \(minutesUsed) \(limitMinutes)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("minor.gotIt", action: onDismiss)
                .font(.subheadline.weight(.medium))
                .buttonStyle(.bordered)
                .tint(.orange)
        }
        .padding(SCTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: SCTheme.CornerRadius.lg)
                        .stroke(.orange.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal, SCTheme.Spacing.md)
    }
}
