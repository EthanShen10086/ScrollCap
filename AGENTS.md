# ScrollCap - Agent & Contributor Guide

## Project Overview

ScrollCap is a multi-platform (iOS / iPadOS / macOS) scrolling long screenshot app built with SwiftUI.

## Quick Start

```bash
git clone https://github.com/EthanShen10086/ScrollCap.git
cd ScrollCap
bash setup.sh          # Installs Xcode CLI tools, SwiftLint, SwiftFormat, Git hooks
open ScrollCap.xcodeproj
```

## Architecture

```
ScrollCap/
├── App/
│   ├── Shared/            # Cross-platform views, ViewModels, services
│   ├── iOS/               # iOS-specific views and extensions
│   └── macOS/             # macOS-specific views and extensions
├── Packages/
│   ├── SharedModels/      # Data types (Screenshot, CaptureState, etc.)
│   ├── DesignSystem/      # Theme, reusable components, modifiers
│   ├── StitchingEngine/   # Image alignment and stitching
│   ├── CaptureKit/        # Capture service protocol + platform implementations
│   └── ImageEditor/       # Annotation and crop tools
├── BroadcastExtension/    # iOS ReplayKit extension
├── ScrollCapWidget/       # WidgetKit extension
└── scripts/               # Git hooks, setup scripts
```

## Key Conventions

1. **State**: `AppState` = global truth. `CaptureViewModel` = capture flow. Sync via `bind(to:)`.
2. **Errors**: Always use `SCError`. Present via `ErrorPresenter.shared.present(_:)`.
3. **Network**: Always use `APIClient.shared`. Never raw `URLSession`.
4. **i18n**: ALL user-visible strings in `Localizable.strings` (en + zh-Hans).
5. **Accessibility**: All interactive elements need localized `accessibilityLabel`.
6. **Code Quality**: SwiftLint + SwiftFormat enforced via pre-commit hooks.
7. **Commits**: Conventional Commits format (`feat:`, `fix:`, `refactor:`, etc.).

## User Modes

- **Standard**: Full features.
- **Minor**: Hides payment, tracks usage time, simplified UI.
- **Elder**: Larger text/buttons, higher contrast, reduced animations.

Mode is set via `AppState.userMode` and propagated through `@Environment(\.userMode)`.

## Testing

- Select `ScrollCap-macOS` or `ScrollCap-iOS` scheme in Xcode.
- Use Personal Team signing (free Apple ID) for development.
- StoreKit testing: use StoreKit Configuration file in Xcode.

## Documentation

- `REQUIREMENTS.md`: Feature specifications and implementation status.
- `.cursor/rules/`: AI assistant conventions for this project.
