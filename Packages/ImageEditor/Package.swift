// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ImageEditor",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ImageEditor", targets: ["ImageEditor"])
    ],
    dependencies: [
        .package(path: "../SharedModels")
    ],
    targets: [
        .target(
            name: "ImageEditor",
            dependencies: ["SharedModels"]
        ),
        .testTarget(
            name: "ImageEditorTests",
            dependencies: ["ImageEditor"]
        )
    ]
)
