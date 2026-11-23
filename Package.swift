// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CoffeeTray",
    platforms: [
        // SMAppService requires macOS 13; that's our floor.
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "CoffeeTray",
            path: "Sources/CoffeeTray"
        )
    ]
)
