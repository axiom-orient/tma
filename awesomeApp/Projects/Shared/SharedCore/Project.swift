import ProjectDescription

let organizationName = "axient"
let bundleIdPrefix = "com.axiomorient"
let deploymentTarget: DeploymentTargets = .iOS("17.0")

let project = Project(
    name: "SharedCore",
    organizationName: organizationName,
    settings: .settings(
        base: [:],
        defaultSettings: .recommended()
    ),
    targets: [
        .target(
            name: "SharedCore",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.axiomorient.SharedCore",
            deploymentTargets: deploymentTarget,
            buildableFolders: ["Sources"],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "Dependencies"),
                .external(name: "Sharing")
            ],
            settings: .settings(
                base: [:],
                defaultSettings: .recommended()
            )
        )
    ]
)
