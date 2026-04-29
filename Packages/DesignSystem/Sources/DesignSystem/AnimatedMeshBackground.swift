import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
public struct AnimatedMeshBackground: View {
    @State private var phase: CGFloat = 0
    let opacity: Double

    public init(opacity: Double = 0.6) {
        self.opacity = opacity
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            MeshGradient(
                width: 3,
                height: 3,
                points: meshPoints(time: time),
                colors: meshColors
            )
        }
        .opacity(opacity)
        .ignoresSafeArea()
    }

    private func meshPoints(time: TimeInterval) -> [SIMD2<Float>] {
        let t = Float(time) * 0.15
        return [
            SIMD2(0.0, 0.0),
            SIMD2(0.5, 0.0),
            SIMD2(1.0, 0.0),
            SIMD2(0.0 + sin(t) * 0.05, 0.5),
            SIMD2(0.5 + cos(t * 1.3) * 0.08, 0.5 + sin(t * 0.7) * 0.06),
            SIMD2(1.0 + sin(t * 0.9) * 0.04, 0.5),
            SIMD2(0.0, 1.0),
            SIMD2(0.5, 1.0),
            SIMD2(1.0, 1.0)
        ]
    }

    private var meshColors: [Color] {
        [
            Color(red: 0.05, green: 0.1, blue: 0.25),
            Color(red: 0.0, green: 0.25, blue: 0.6),
            Color(red: 0.15, green: 0.1, blue: 0.4),
            Color(red: 0.0, green: 0.35, blue: 0.7),
            Color(red: 0.2, green: 0.15, blue: 0.55),
            Color(red: 0.35, green: 0.2, blue: 0.7),
            Color(red: 0.05, green: 0.15, blue: 0.35),
            Color(red: 0.15, green: 0.2, blue: 0.5),
            Color(red: 0.3, green: 0.15, blue: 0.5)
        ]
    }
}

public struct BrandBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        Group {
            if #available(iOS 18.0, macOS 15.0, *) {
                ZStack {
                    baseColor
                    AnimatedMeshBackground(opacity: colorScheme == .dark ? 0.5 : 0.3)
                }
            } else {
                ZStack {
                    baseColor
                    LinearGradient(
                        colors: [
                            SCTheme.Colors.brandBlue.opacity(0.1),
                            SCTheme.Colors.brandPurple.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        }
        .ignoresSafeArea()
    }

    private var baseColor: some View {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemBackground)
        #endif
    }
}
