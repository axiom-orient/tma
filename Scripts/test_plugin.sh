#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
  echo -e "${BLUE}[INFO] $1${NC}"
}

log_success() {
  echo -e "${GREEN}[OK]   $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}[WARN] $1${NC}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
SAMPLE_PROJECT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/apptma-sample.XXXXXX")"
APP_NAME="SampleApp"
WORKSPACE_NAME="AppTMASample"

cleanup() {
  rm -rf "$SAMPLE_PROJECT_DIR"
}

trap cleanup EXIT

if [ "$(uname -s)" != "Darwin" ]; then
  echo "[ERROR] this smoke test must run on macOS (Darwin)." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "[ERROR] xcodebuild not found. Install Xcode command line tools and retry." >&2
  exit 1
fi

log_info "apptma plugin smoke test start"
log_info "plugin root: ${PLUGIN_ROOT}"
log_info "sample root: ${SAMPLE_PROJECT_DIR}"
cd "$SAMPLE_PROJECT_DIR"

mkdir -p Tuist

cat > Tuist.swift << TUIST_EOF
import ProjectDescription

let tuist = Tuist(
  project: .tuist(
    plugins: [
      .local(path: "${PLUGIN_ROOT}")
    ]
  )
)
TUIST_EOF

cat > Tuist/Package.swift << 'PACKAGE_EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Packages",
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.4")
  ]
)
PACKAGE_EOF

cat > Workspace.swift << WORKSPACE_EOF
import ProjectDescription

let workspace = Workspace(
  name: "${WORKSPACE_NAME}",
  projects: [
    "Projects/**"
  ]
)
WORKSPACE_EOF

log_info "verify templates"
TEMPLATE_LIST="$(tuist scaffold list || true)"
for required in app feature domain service shared; do
  if ! printf "%s\n" "$TEMPLATE_LIST" | grep -Eq "^[[:space:]]*${required}[[:space:]]"; then
    echo "[ERROR] required scaffold template missing: ${required}" >&2
    printf "%s\n" "$TEMPLATE_LIST" >&2
    exit 1
  fi
done
log_success "all required templates are present"

log_info "scaffold modules"
tuist scaffold feature --name Root
tuist scaffold domain --name User
tuist scaffold service --name Auth
tuist scaffold shared --name DesignSystem
tuist scaffold app --name "$APP_NAME" --root-feature-name Root

log_success "scaffold completed"

SHARED_TESTS_DIR="Projects/Shared/DesignSystem/Tests"
if [ -d "$SHARED_TESTS_DIR" ]; then
  echo "[ERROR] shared template must not generate tests directory: ${SHARED_TESTS_DIR}" >&2
  exit 1
fi
log_success "shared template generated without tests directory"

log_info "generated structure"
find Projects -maxdepth 3 -type d | sort

log_info "tuist install"
tuist install

log_info "tuist generate"
tuist generate --no-open

WORKSPACE_PATH="${WORKSPACE_NAME}.xcworkspace"
if [ ! -d "$WORKSPACE_PATH" ]; then
  log_warning "workspace not found at ${WORKSPACE_PATH}; skip xcodebuild"
  exit 0
fi

log_info "load scheme list from workspace"
SCHEME_LIST="$(xcodebuild -workspace "$WORKSPACE_PATH" -list)"

assert_scheme() {
  local scheme_name="$1"
  if ! printf "%s\n" "$SCHEME_LIST" | grep -Eq "^[[:space:]]+${scheme_name}$"; then
    echo "[ERROR] required scheme not found: ${scheme_name}" >&2
    echo "----- scheme list -----" >&2
    printf "%s\n" "$SCHEME_LIST" >&2
    exit 1
  fi
}

EXPECTED_SCHEMES=(
  "$APP_NAME"
  "RootFeature"
  "UserDomain"
  "AuthService"
  "DesignSystem"
)

for scheme in "${EXPECTED_SCHEMES[@]}"; do
  assert_scheme "$scheme"
done

log_info "xcodebuild validation (explicit schemes only, no name inference)"
for scheme in "${EXPECTED_SCHEMES[@]}"; do
  log_info "building scheme: ${scheme}"
  xcodebuild \
    -workspace "$WORKSPACE_PATH" \
    -scheme "$scheme" \
    -configuration Debug \
    -destination 'generic/platform=iOS' \
    build >/tmp/apptma_build_${scheme}.log 2>&1 || {
      tail -50 /tmp/apptma_build_${scheme}.log >&2
      exit 1
    }
done

log_success "apptma plugin smoke test done"
