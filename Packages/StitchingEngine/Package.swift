// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StitchingEngine",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "StitchingEngine", targets: ["StitchingEngine"]),
    ],
    dependencies: [
        .package(path: "../SharedModels"),
    ],
    targets: [
        .target(
            name: "StitchingEngine",
            dependencies: ["SharedModels"]
        ),
        .testTarget(
            name: "StitchingEngineTests",
            dependencies: ["StitchingEngine"]
        ),
    ]
)
