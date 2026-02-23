# tuist modualer architecture

Tuist(iOS)에서 **App / Feature / Domain / Service / Shared 모듈을 일관된 규칙으로 scaffold**하기 위한 플러그인입니다.  
이 저장소는 템플릿 정의, 검증 스크립트, 운영 문서를 함께 관리합니다.

## 목차
- [1. 개요](#1-개요)
- [2. 제공 템플릿](#2-제공-템플릿)
- [3. 요구사항](#3-요구사항)
- [4. 설치 (소비 프로젝트)](#4-설치-소비-프로젝트)
- [5. 빠른 시작](#5-빠른-시작)
- [6. 템플릿별 상세 사용법](#6-템플릿별-상세-사용법)
- [7. 생성 결과 계약](#7-생성-결과-계약)
- [8. 의존성 주입 규칙](#8-의존성-주입-규칙)
- [9. 검증 방법](#9-검증-방법)
- [10. 릴리즈 체크리스트](#10-릴리즈-체크리스트)
- [11. 트러블슈팅](#11-트러블슈팅)
- [12. 저장소 구조](#12-저장소-구조)
- [13. 유지보수 원칙](#13-유지보수-원칙)

## 1. 개요

### 목표
- 신규 모듈 생성 시간을 단축한다.
- 팀 내 모듈 구조/타겟/스킴 네이밍을 표준화한다.
- 생성 후 바로 `tuist generate` + `xcodebuild` 검증이 가능하도록 한다.

### 핵심 원칙
- **수작업 생성 금지**: 모듈 디렉터리/Project.swift를 직접 만들지 않고 `tuist scaffold`만 사용.
- **경계 우선**: Domain/Service는 기본값을 `Unimplemented`로 두고 App에서 명시 주입.
- **검증 우선**: 릴리즈 전 `Scripts/test_plugin.sh`를 필수로 실행.

## 2. 제공 템플릿

| 템플릿 | 생성 위치 | 기본 타겟 | 테스트 |
| --- | --- | --- | --- |
| `app` | `Projects/App` | `<AppName>`, `<AppName>Tests` | 생성 |
| `feature` | `Projects/Features/<Name>` | `<Name>Feature`, `<Name>FeatureTests` | 생성 |
| `domain` | `Projects/Domains/<Name>` | `<Name>DomainInterface`, `<Name>DomainSources` | 생성 |
| `service` | `Projects/Services/<Name>` | `<Name>ServiceInterface`, `<Name>ServiceSources`, `<Name>ServiceTests` | 생성 |
| `shared` | `Projects/Shared/<Name>` | `<Name>` | 미생성 |

## 3. 요구사항

### 필수 도구
- Xcode (iOS 빌드 가능 환경)
- Tuist
- Bash (`Scripts/test_plugin.sh` 실행용)

### 권장 버전 관리
이 저장소는 `.mise.toml`을 제공합니다.

```toml
[tools]
tuist = "4.52.0"
```

권장 실행:

```bash
mise install
```

## 4. 설치 (소비 프로젝트)

소비 프로젝트 루트에서 아래 파일을 구성합니다.

### 4.1 `Tuist.swift`

```swift
import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        plugins: [
            .local(path: "/absolute/path/to/tma")
        ]
    )
)
```

### 4.2 `Workspace.swift`

```swift
import ProjectDescription

let workspace = Workspace(
    name: "MyWorkspace",
    projects: [
        "Projects/**"
    ]
)
```

### 4.3 `Tuist/Package.swift`

```swift
import PackageDescription

let package = Package(
    name: "Packages",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.4")
    ]
)
```

주의:
- `from: "x.y.z"`는 최소 버전 제약입니다. 실제 해석 버전은 `Package.resolved`에 고정됩니다.
- 버전 상향/하향 시 생성 결과 빌드 검증을 반드시 다시 수행하세요.

## 5. 빠른 시작

```bash
tuist scaffold list

tuist scaffold feature --name Root
tuist scaffold domain --name User
tuist scaffold service --name Auth
tuist scaffold shared --name DesignSystem
tuist scaffold app --name MyApp --root-feature-name Root

tuist install
tuist generate
```

생성 후 기본 디렉터리 예시:

```text
Projects/
  App/
  Features/Root/
  Domains/User/
  Services/Auth/
  Shared/DesignSystem/
```

## 6. 템플릿별 상세 사용법

### 6.1 app

```bash
tuist scaffold app --name MyApp --root-feature-name Root
```

지원 속성:
- `--name` (필수)
- `--organization-name` (기본: `axient`)
- `--bundle-id-prefix` (기본: `com.example`)
- `--team-id` (기본: 빈 문자열)
- `--deployment-target` (기본: `17.0`)
- `--root-feature-name` (기본: `Root`)

### 6.2 feature

```bash
tuist scaffold feature --name Profile
```

지원 속성:
- `--name` (필수)
- `--organization-name` (기본: `axient`)
- `--bundle-id-prefix` (기본: `com.axiomorient`)
- `--team-id` (기본: 빈 문자열)
- `--deployment-target` (기본: `17.0`)

### 6.3 domain

```bash
tuist scaffold domain --name User
```

지원 속성:
- `--name` (필수)
- `--organization-name` (기본: `axient`)
- `--bundle-id-prefix` (기본: `com.axiomorient`)
- `--team-id` (기본: 빈 문자열)
- `--deployment-target` (기본: `17.0`)

### 6.4 service

```bash
tuist scaffold service --name Auth
```

지원 속성:
- `--name` (필수)
- `--organization-name` (기본: `axient`)
- `--bundle-id-prefix` (기본: `com.axiomorient`)
- `--team-id` (기본: 빈 문자열)
- `--deployment-target` (기본: `17.0`)

### 6.5 shared

```bash
tuist scaffold shared --name DesignSystem
```

지원 속성:
- `--name` (필수)
- `--organization-name` (기본: `axient`)
- `--bundle-id-prefix` (기본: `com.axiomorient`)
- `--team-id` (기본: 빈 문자열)
- `--deployment-target` (기본: `17.0`)

## 7. 생성 결과 계약

### 스킴 네이밍 규칙
- App: `<AppName>`
- Feature: `<Name>Feature`
- Domain: `<Name>Domain`
- Service: `<Name>Service`
- Shared: `<Name>`

### Shared 정책
- `shared` 템플릿은 기본적으로 `Tests` 디렉터리를 생성하지 않습니다.

### Domain/Service 정책
- 기본 구현은 `Unimplemented` 의존성 값을 포함합니다.
- 실제 Live 구현은 App 레이어에서 주입해야 정상 동작합니다.

## 8. 의존성 주입 규칙

App에서 `prepareDependencies`를 통해 live 구현을 연결합니다.

```swift
import Dependencies
import UserDomainSources
import AuthServiceSources

public struct AppComposition {
    public static func configureLiveDependencies() {
        prepareDependencies {
            $0.userUseCase = DefaultUserUseCase()
            $0.authService = LiveAuthService()
        }
    }
}
```

권장:
- Domain/Service를 생성한 즉시 AppComposition을 업데이트하여 런타임 `Unimplemented` 진입을 방지합니다.

## 9. 검증 방법

### 9.1 스모크 테스트(권장, 릴리즈 필수)

```bash
bash Scripts/test_plugin.sh
```

환경 요구:
- macOS (Darwin)
- Xcode + `xcodebuild`

스크립트가 수행하는 검증:
- `tuist scaffold list`로 템플릿 존재 확인 (`app/feature/domain/service/shared`)
- 샘플 프로젝트 생성 및 5개 모듈 scaffold
- Shared에 `Tests`가 생성되지 않았는지 확인
- `tuist install` / `tuist generate --no-open`
- `xcodebuild -list`에서 기대 스킴 존재 확인
- 기대 스킴 빌드 검증:
  - `SampleApp`
  - `RootFeature`
  - `UserDomain`
  - `AuthService`
  - `DesignSystem`

### 9.2 수동 검증

```bash
xcodebuild -workspace MyWorkspace.xcworkspace -list
xcodebuild -workspace MyWorkspace.xcworkspace -scheme MyApp -destination 'generic/platform=iOS' build
```

주의:
- 스킴명은 추정하지 말고 `-list` 결과를 그대로 사용합니다.

### 9.3 mise task 사용

```bash
mise run bootstrap
mise run test
mise run cache-warm
```

## 10. 릴리즈 체크리스트

릴리즈 전 아래 항목을 모두 만족해야 합니다.

- [ ] `README.md`가 현재 템플릿 동작과 일치한다.
- [ ] `bash Scripts/test_plugin.sh`가 성공한다.
- [ ] Shared 템플릿이 `Tests`를 생성하지 않는다.
- [ ] App/Feature/Domain/Service/Shared 스킴 빌드가 성공한다.
- [ ] 불필요한 생성 산출물(`.tuist`, `.build`, `DerivedData`, `Tuist/.build`)이 커밋 대상에 없다.

## 11. 트러블슈팅

### Q1. `tuist scaffold list`에 템플릿이 안 보입니다.
원인:
- `Tuist.swift`의 플러그인 경로가 잘못됨.

조치:
- `Tuist.swift`의 `.local(path: ...)`가 이 저장소 절대경로를 가리키는지 확인.

### Q2. `xcodebuild`에서 스킴을 찾지 못합니다.
원인:
- `tuist generate` 미실행 또는 스킴명 오타.

조치:
- `tuist generate --no-open`
- `xcodebuild -workspace <Workspace>.xcworkspace -list` 결과에서 스킴명 재확인.

### Q3. Domain/Service 호출 시 런타임 에러가 납니다.
원인:
- App에서 live 의존성을 주입하지 않아 `Unimplemented`가 호출됨.

조치:
- `AppComposition`에 Domain/Service live 구현을 명시 주입.

### Q4. 의존성 버전 충돌이 발생합니다.
원인:
- `Tuist/Package.swift` 수정 후 lock 정합성 불일치.

조치:
- `tuist install` 재실행 후 lock 갱신.
- 다시 `bash Scripts/test_plugin.sh` 실행.

## 12. 저장소 구조

```text
.
├── Plugin.swift
├── Tuist.swift
├── README.md
├── Scripts/
│   └── test_plugin.sh
├── Templates/
│   ├── app/
│   ├── feature/
│   ├── domain/
│   ├── service/
│   └── shared/
└── Tuist/
    ├── Package.swift
    └── Package.resolved
```

## 13. 유지보수 원칙

- 문서는 이 README를 단일 기준으로 유지합니다.
- 템플릿 수정 시 문서를 같은 PR에서 함께 갱신합니다.
- 완료된 계획/태스크 문서는 누적하지 않습니다.
- 배포 전 스모크 테스트를 통과하지 못하면 릴리즈하지 않습니다.
