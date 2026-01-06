import SwiftUI
import ComposableArchitecture
import Dependencies

// ============================================================
// 🔧 앱별 커스터마이징 가이드 (Per-App Customization Guide)
// ============================================================
//
// 새 앱 생성 시 수정이 필요한 파일들:
//
// 📌 필수 수정 (Must Modify)
// ─────────────────────────────────────────────────────────────
// 1. MainScreenView.swift    - 메인 화면 UI 구현
// 2. SplashView.swift        - 스플래시 로고, 브랜딩
// 3. AppConstants.swift      - App.appStoreId 설정 (Force Update용)
//
// 📌 선택적 수정 (Optional)
// ─────────────────────────────────────────────────────────────
// 4. AppState.swift          - selectedTabIndex 기본값 (탭 수에 맞게)
// 5. DeepLink.swift          - 앱별 딥링크 경로 추가
// 6. AppConstants.swift      - 커스텀 Remote Config 키 추가
//
// 📦 수정 불필요 (Template Core - Do Not Modify)
// ─────────────────────────────────────────────────────────────
// - ApplicationLifecycle.swift (Lifecycle orchestration)
// - UpdateChecker.swift        (Version comparison logic)
// - StoreVersionChecker.swift  (App Store version fetch)
// - RemoteConfigServices.swift (Firebase integration)
// - AppReducer.swift           (State management core)
//
// ============================================================

@main
struct awesomeAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var deepLinkStore: DeepLinkStore
    private let store: StoreOf<AppReducer>

    init() {
        let deepLinkStore = DeepLinkStore()
        _deepLinkStore = StateObject(wrappedValue: deepLinkStore)
        self.store = Store(initialState: AppReducer.State()) {
            AppReducer()
        } withDependencies: { values in
            AppComposition.configureAll(&values)
        }
        appDelegate.configure(deepLinkStore: deepLinkStore)
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .environmentObject(deepLinkStore)
                .task {
                    store.send(.view(.appDidLaunch))
                }
                .onChange(of: store.lifecycle.phase) { _, newPhase in
                    store.send(.lifecycle(.view(.scenePhaseChanged(newPhase))))
                }
        }
    }
}

// MARK: - Root View

private struct RootView: View {
    let store: StoreOf<AppReducer>
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            switch store.rootViewState {
            case .splash:
                SplashView(welcomeMessage: store.welcomeMessage) {
                    // Splash animation completed - notify the reducer
                    store.send(.view(.splashAnimationCompleted))
                }
                
            case let .maintenance(message):
                MaintenanceView(
                    message: message,
                    onRefresh: { store.send(.view(.retryColdStart)) }
                )
                
            case let .forceUpdate(version):
                ForceUpdateView(
                    requiredVersion: version,
                    storeURL: AppConstants.App.appStoreURL
                )
                
            case let .error(message):
                ErrorView(
                    message: message,
                    onRetry: { store.send(.view(.retryColdStart)) }
                )
                
            case .main:
                MainScreenView(store: store)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: store.rootViewState)
        .onChange(of: scenePhase) { _, newPhase in
            store.send(.lifecycle(.view(.scenePhaseChanged(newPhase))))
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("연결 오류")
                .font(.title2.bold())
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                Text("다시 시도")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}
