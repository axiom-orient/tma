import ProjectDescription

let organizationName = "axient"
let bundleIdPrefix = "com.axiomorient"
let appName = "awesomeApp"
let appBundleId = "com.axiomorient.awesomeapp"
let deploymentTarget: DeploymentTargets = .iOS("17.0")
let teamID = "7WR76382QB"
let appInfoPlist: [String: Plist.Value] = [
    "UILaunchScreen": .dictionary([:]),
    "UIRequiresFullScreen": .boolean(true),
    "UISupportedInterfaceOrientations": .array([.string("UIInterfaceOrientationPortrait")]),
    "UIUserInterfaceStyle": .string("Light"),
    // Deep Link Configuration
    "CFBundleURLTypes": .array([
        .dictionary([
            "CFBundleTypeRole": .string("Editor"),
            "CFBundleURLName": .string(bundleIdPrefix),
            "CFBundleURLSchemes": .array([.string("awesomeapp")])
        ])
    ])
]

let crashlyticsUploadScript: TargetScript = .post(
    script: """
    set -euo pipefail

    if [ "$CONFIGURATION" = "Debug" ]; then
        echo "[Crashlytics] Skip dSYM upload for Debug build"
        exit 0
    fi

    if [ -z "${BUILD_DIR:-}" ]; then
        echo "[Crashlytics] BUILD_DIR is not set, skipping Crashlytics upload"
        exit 0
    fi

    SCRIPT_PATH="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"

    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "[Crashlytics] Run script not found at $SCRIPT_PATH"
        exit 0
    fi

    "$SCRIPT_PATH"
    """,
    name: "Firebase Crashlytics",
    outputPaths: [
        "$(DERIVED_FILE_DIR)/crashlytics-upload.log"
    ],
    basedOnDependencyAnalysis: false
)

let baseSettings: SettingsDictionary = [
    "ENABLE_USER_SCRIPT_SANDBOXING": .string("YES"),
    "ENABLE_MODULE_VERIFIER": .string("YES"),
    "SWIFT_STRICT_CONCURRENCY": .string("targeted"),
    "OTHER_LDFLAGS": .array(["$(inherited)", "-ObjC"]),
    "DEVELOPMENT_TEAM": .string(teamID)]

let project = Project(
    name: appName,
    organizationName: organizationName,
    settings: .settings(
        base: baseSettings,
        defaultSettings: .recommended()
    ),
    targets: [
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: appBundleId,
            deploymentTargets: deploymentTarget,
            infoPlist: .extendingDefault(with: appInfoPlist),
            resources: ["Resources/**"],
            buildableFolders: ["Sources"],
            entitlements: "App.entitlements",
            scripts: [crashlyticsUploadScript],
            dependencies: [
                .project(target: "SharedCore", path: .relativeToRoot("Projects/Shared/SharedCore")),
                .project(target: "DailyActionList", path: .relativeToRoot("Projects/Features/DailyActionList")),
                .project(target: "AppDataService", path: .relativeToRoot("Projects/Service/AppDataService")),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseRemoteConfig"),
                .external(name: "FirebaseCrashlytics"),
                .external(name: "Sharing")
            ],
            settings: .settings(
                base: baseSettings,
                defaultSettings: .recommended()
            )
        )
    ]
)
