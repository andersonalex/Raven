// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Raven",
    platforms: [.iOS(.v13), .macOS(.v10_15), .macCatalyst(.v13), .tvOS(.v13), .watchOS(.v4)],
    products: [
        .library(
            name: "Raven",
            targets: ["Raven"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Raven",
            dependencies: []),
        .testTarget(
            name: "RavenTests",
            dependencies: ["Raven"]),
    ]
)
