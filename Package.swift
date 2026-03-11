// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NetworkRouter",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "NetworkRouter",
            path: "Sources/NetworkRouter"
        ),
    ]
)
