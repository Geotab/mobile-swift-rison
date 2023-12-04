// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SwiftRison",
    products: [
        .library(
            name: "SwiftRison",
            targets: ["SwiftRison"]),
    ],
    targets: [
        .target(
            name: "SwiftRison",
            dependencies: []),
        .testTarget(
            name: "SwiftRisonTests",
            dependencies: ["SwiftRison"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
