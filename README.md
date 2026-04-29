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

## Architecture

```
ScrollCap/
├── App/                         # Application layer
│   ├── Shared/                  # Cross-platform SwiftUI views
│   ├── iOS/                     # iOS/iPadOS-specific views
│   └── macOS/                   # macOS-specific views (MenuBarExtra, region selector)
├── BroadcastExtension/          # iOS ReplayKit Broadcast Upload Extension
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

### 2. Generate Xcode Project

```bash
brew install xcodegen   # if not already installed
xcodegen generate
```

### 3. Open & Build

```bash
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

## Tech Stack

- **SwiftUI** — declarative UI framework
- **ScreenCaptureKit** — macOS screen capture (macOS 14+)
- **ReplayKit** — iOS screen recording
- **Vision** — image alignment and registration
- **Swift Package Manager** — modular dependency management
- **XcodeGen** — Xcode project generation from YAML

## License

MIT License — see [LICENSE](LICENSE) for details.
