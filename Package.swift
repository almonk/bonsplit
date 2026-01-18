// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SplitTabBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SplitTabBar",
            targets: ["SplitTabBar"]
        ),
    ],
    targets: [
        .target(
            name: "SplitTabBar",
            dependencies: [],
            path: "Sources/SplitTabBar"
        ),
        .testTarget(
            name: "SplitTabBarTests",
            dependencies: ["SplitTabBar"],
            path: "Tests/SplitTabBarTests"
        ),
    ]
)
