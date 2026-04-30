# ScrollCap

**English** | [简体中文](README.zh-Hans.md)

A native SwiftUI scrolling screenshot tool for iOS, iPadOS, and macOS. Capture long, scrollable content as a single stitched image — no paid developer account required.

## Features

- **Scroll Capture**: Record scrolling content and automatically stitch frames into a single long screenshot
- **Cross-Platform**: Runs natively on iPhone, iPad, and Mac with adaptive UI
- **Liquid Glass Design**: Supports Apple's Liquid Glass design language (iOS 26+ / macOS 26+) with graceful fallback for older systems
- **Vision-Powered Stitching**: Uses Apple's Vision framework (`VNTranslationalImageRegistrationRequest`) for pixel-accurate frame alignment
- **Zero Dependencies**: Built entirely with Apple-native frameworks — no third-party libraries
- **Image Editor**: Crop, annotate, and export in PNG/JPEG/HEIC/PDF formats
- **OCR Text Recognition**: Extract Chinese and English text from screenshots
- **iCloud Sync**: Cross-device screenshot history synchronization
- **Widget**: Home Screen / Lock Screen one-tap quick capture
- **Multiple Payment Methods**: App Store, Apple Pay, Stripe, WeChat Pay, Alipay, PayPal
- **Minor Mode**: Hide payments, limit usage time, simplified interface
- **Elder-Friendly Mode**: Large fonts, large buttons, high contrast, reduced animations

## Architecture

```
ScrollCap/
├── App/                         # Application layer
│   ├── Shared/                  # Cross-platform SwiftUI views
│   ├── iOS/                     # iOS/iPadOS-specific views
│   └── macOS/                   # macOS-specific views (MenuBarExtra, region selector)
├── BroadcastExtension/          # iOS ReplayKit Broadcast Upload Extension
├── ScrollCapWidget/             # WidgetKit widget extension
└── Packages/                    # Modular Swift Packages
    ├── SharedModels/            # Data models shared across all modules
    ├── DesignSystem/            # Liquid Glass compat, theme, adaptive navigation
    ├── CaptureKit/              # Platform-abstracted capture service
    │   ├── CaptureKit/          # Shared protocols
    │   ├── CaptureKitMac/       # macOS: ScreenCaptureKit implementation
    │   └── CaptureKitIOS/       # iOS: ReplayKit implementation
    ├── StitchingEngine/         # Vision-based image alignment and stitching
    └── ImageEditor/             # Crop, annotate, export tools
```

### Design Principles

- **Clean Architecture + MVVM** — business logic is 100% shared, UI adapts per platform
- **Protocol-Oriented Abstraction** — `CaptureService` protocol unifies macOS/iOS capture
- **Swift Observation** — modern `@Observable` state management
- **SwiftUI Environment DI** — no third-party dependency injection

### Platform Capture Strategy

| Platform | Framework | Method |
|----------|-----------|--------|
| macOS | ScreenCaptureKit | Region-based frame capture during scroll |
| iOS/iPadOS | ReplayKit | Broadcast Extension screen recording |
| All | Vision | `VNTranslationalImageRegistrationRequest` for stitching |

## Requirements

- **macOS 14.0+** / **iOS 17.0+**
- Xcode 16.0+ (with Swift 6.0)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for project generation)

## Getting Started

### 1. Clone

```bash
git clone https://github.com/EthanShen10086/ScrollCap.git
cd ScrollCap
```

### 2. One-Click Setup (Recommended)

```bash
bash setup.sh
```

This script automatically installs XcodeGen, SwiftLint, SwiftFormat, configures Git Hooks, generates and opens the Xcode project.

### 3. Manual Setup

```bash
brew install xcodegen   # if not already installed
xcodegen generate
open ScrollCap.xcodeproj
```

- Select **ScrollCap-macOS** scheme to build for Mac
- Select **ScrollCap-iOS** scheme to build for iPhone/iPad simulator
- For device testing: set **Signing > Team** to your Personal Team (free Apple ID)

### Testing Without a Developer Account

- **Simulator**: Works out of the box, no account needed
- **Real Device (Sideload)**:
  1. In Xcode, go to Signing & Capabilities
  2. Select your Personal Team (free Apple ID)
  3. Build and run to your device
  4. On device: Settings > General > VPN & Device Management > Trust your certificate
  5. App expires after 7 days — rebuild to renew
- **macOS**: Build & Run directly, no special signing needed

## Code Quality

- **SwiftLint** + **SwiftFormat** — automatic code style checking
- **Git Hooks** — pre-commit auto lint, commit messages follow Conventional Commits
- **CI/CD** — GitHub Actions automated build and checks

## Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Swift 6 |
| UI Framework | SwiftUI |
| State Management | `@Observable` + SwiftUI Environment |
| macOS Capture | ScreenCaptureKit |
| iOS Capture | ReplayKit + Broadcast Extension |
| Image Alignment | Vision Framework |
| Text Recognition | Vision Framework |
| In-App Purchase | StoreKit 2 |
| Cloud Sync | iCloud Documents |
| Widgets | WidgetKit + AppIntents |
| Project Generation | XcodeGen |
| Third-Party Dependencies | **Zero** |

## License

MIT License — see [LICENSE](LICENSE) for details.
