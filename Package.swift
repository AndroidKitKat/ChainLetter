// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ChainLetter",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "ChainLetter",
            targets: ["ChainLetter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "ChainLetter"),
        .testTarget(
            name: "ChainLetterTests",
            dependencies: ["ChainLetter"]
        ),
    ]
)

