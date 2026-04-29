// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CaptureKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "CaptureKit", targets: ["CaptureKit"]),
        .library(name: "CaptureKitMac", targets: ["CaptureKitMac"]),
        .library(name: "CaptureKitIOS", targets: ["CaptureKitIOS"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
        .package(path: "../StitchingEngine"),
    ],
    targets: [
        .target(
            name: "CaptureKit",
            dependencies: ["SharedModels"]
        ),
        .target(
            name: "CaptureKitMac",
            dependencies: ["CaptureKit", "SharedModels", "StitchingEngine"]
        ),
        .target(
            name: "CaptureKitIOS",
            dependencies: ["CaptureKit", "SharedModels", "StitchingEngine"]
        ),
        .testTarget(
            name: "CaptureKitTests",
            dependencies: ["CaptureKit"]
        ),
    ]
)
