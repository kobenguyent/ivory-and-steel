// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "IvoryAndSteel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "IvoryAndSteel",
            targets: ["IvoryAndSteel"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "IvoryAndSteel",
            path: "Sources/IvoryAndSteel",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "IvoryAndSteelTests",
            dependencies: ["IvoryAndSteel"],
            path: "Tests/IvoryAndSteelTests"
        )
    ]
)

