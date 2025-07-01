// swift-tools-version:5.10

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
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault"),
                .enableUpcomingFeature("DisableOutwardActorInference"),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("IsolatedDefaultValues"),
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitlyOpenedExistentials"),
            ]),
        .testTarget(
            name: "SwiftRisonTests",
            dependencies: ["SwiftRison"]),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)


