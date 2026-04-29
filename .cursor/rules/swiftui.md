# SwiftUI Conventions

## View Structure

- Keep views under 200 lines. Extract sub-views and helpers into separate files.
- Use `MARK: -` comments to section views (Header, Body, Actions, Helpers).
- Prefer `@Environment` for dependency injection over singletons in views.

## Styling

- Use `SCTheme` for all spacing, typography, corner radius, colors.
- Do NOT hardcode colors. Use semantic colors from `SCTheme.Colors` or system `.primary`/`.secondary`.
- Card backgrounds: use `SCTheme.Colors.cardBackground` or `.ultraThinMaterial`.
- Gradients: use `SCTheme.Gradients.brand` for brand elements.

## Modifiers

- Apply `.adaptiveGlass()` for glass-effect containers.
- Apply `.applyUserMode()` at the root level only, not per-view.
- Platform-specific code: use `#if os(macOS)` / `#if os(iOS)` blocks.

## Animations

- Default: `SCTheme.Animation.standard`.
- Respect `@Environment(\.accessibilityReduceMotion)`.
- Elder mode: disable non-essential animations.

## Navigation

- macOS: `NavigationSplitView` with sidebar.
- iOS: `TabView` with tabs.
- iPadOS: Adaptive (follows screen size).
