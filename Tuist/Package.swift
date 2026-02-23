// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Packages",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.4"),
    ]
)
