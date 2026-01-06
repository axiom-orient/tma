// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import ProjectDescription

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework,
        "Dependencies": .framework,
        "Sharing": .framework,
        "Clocks": .framework,
        "CombineSchedulers": .framework,
        "ConcurrencyExtras": .framework,
        "CustomDump": .framework,
        "IdentifiedCollections": .framework,
        "InternalCollectionsUtilities": .framework,
        "IssueReporting": .framework,
        "IssueReportingPackageSupport": .framework,
        "OrderedCollections": .framework,
        "PerceptionCore": .framework,
        "XCTestDynamicOverlay": .framework,
        "SQLiteData": .framework,
        "GRDB": .framework
    ]
)
#endif

let package = Package(
    name: "ProjectDependencies",
    dependencies: [
        // TCA & Dependencies
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.23.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
        // Persistence
        .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
        // Database
        .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.4.2"),
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.0.0")
    ]
)
