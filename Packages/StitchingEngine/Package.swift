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
    targets: [
        .target(
            name: "StitchingEngine"
        ),
        .testTarget(
            name: "StitchingEngineTests",
            dependencies: ["StitchingEngine"]
        ),
    ]
)
