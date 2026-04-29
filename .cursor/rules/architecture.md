# ScrollCap Architecture Rules

## Module Boundaries (SPM)

- **SharedModels**: Zero dependencies. Data types only. No UI, no business logic.
- **DesignSystem**: Zero internal dependencies. Theme, reusable components, modifiers.
- **StitchingEngine**: Depends only on SharedModels. Pure image processing.
- **CaptureKit**: Depends only on SharedModels. Protocol + platform implementations.
- **ImageEditor**: Depends only on SharedModels. Annotation & crop logic.
- **App layer**: Can import all packages. Business logic lives here.

**NEVER** add upward dependencies (e.g. CaptureKit importing DesignSystem).

## State Management

- `AppState` is the single source of truth for global app state (screenshots, settings, user mode).
- `CaptureViewModel` owns capture-specific state and syncs back to `AppState` via `bind(to:)`.
- Do NOT create duplicate state. If ViewModel needs AppState data, read from the bound reference.

## User Mode System

- Mode checks should go through `@Environment(\.userMode)` or the `UserModeAdaptiveModifier`.
- Do NOT scatter `if userMode == .elder` / `.minor` across views. Prefer ViewModifiers.
- Payment-related features: check `AppState.shouldHidePayment` (respects minor mode).

## Error Handling

- All errors must be `SCError` typed. Do NOT throw raw `Error`.
- Present errors via `ErrorPresenter.shared.present(_:)` — it logs, tracks, and shows UI.
- Never silently catch errors. At minimum, log them.

## Network

- All HTTP requests go through `APIClient.shared`. Do NOT use raw `URLSession`.
- Check `NetworkMonitor.shared.isConnected` before network-dependent UI.

## Concurrency

- UI updates: `@MainActor`. Service layers: `actor` isolation.
- Use `async/await` over callbacks where possible.

## i18n

- ALL user-visible strings must use localized keys from `Localizable.strings`.
- Accessibility labels must also be localized (use `Text("key")` not `"English string"`).
- Both `en` and `zh-Hans` localizations must be updated together.

## Code Quality

- SwiftLint + SwiftFormat enforced via pre-commit hook.
- Commit messages follow Conventional Commits: `type(scope): description`.
- Run `swiftlint lint` and `swiftformat --lint .` before submitting PRs.
