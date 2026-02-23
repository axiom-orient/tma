import ProjectDescription

private let sharedNameAttribute: Template.Attribute = .required("name")
private let sharedOrganizationAttribute: Template.Attribute = .optional("organizationName", default: "axient")
private let sharedBundleIdAttribute: Template.Attribute = .optional("bundleIdPrefix", default: "com.axiomorient")
private let sharedTeamAttribute: Template.Attribute = .optional("teamId", default: "")
private let sharedDeploymentTargetAttribute: Template.Attribute = .optional("deploymentTarget", default: "17.0")

let templateShared = Template(
    description: "TMA Shared module (single target, compile-safe minimal scaffold)",
    attributes: [
        sharedNameAttribute,
        sharedOrganizationAttribute,
        sharedBundleIdAttribute,
        sharedTeamAttribute,
        sharedDeploymentTargetAttribute
    ],
    items: [
        .file(path: "Projects/Shared/{{ name }}/Project.swift", templatePath: "Project.stencil"),
        .file(path: "Projects/Shared/{{ name }}/Sources/{{ name }}.swift", templatePath: "SharedSources.stencil"),
        .file(path: "Projects/Shared/{{ name }}/Sources/{{ name }}Keys.swift", templatePath: "SharedKeys.stencil"),
        .file(path: "Projects/Shared/{{ name }}/Sources/{{ name }}AnySendableError.swift", templatePath: "SharedAnySendableError.stencil")
    ]
)
