import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        plugins: [
            .local(path: "/Users/axient/repository/MGen/templates/ios")
        ],
        generationOptions: .options(
            resolveDependenciesWithSystemScm: true,
            disableSandbox: true
        )
    )
)
