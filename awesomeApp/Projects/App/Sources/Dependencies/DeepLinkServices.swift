import Foundation
import OSLog
import Dependencies
import DependenciesMacros
import SharedCore

// MARK: - Deep Link Client (TCA Dependency)

/// Functional deep link service using @DependencyClient macro.
/// Handles custom schemes, universal links, and deferred deep links.
@DependencyClient
public struct DeepLinkClient: Sendable {
    /// Parse a URL into a strongly-typed route
    public var parse: @Sendable (_ url: URL) -> DeepLinkRoute = { _ in .home(date: nil) }
    
    /// Check if the URL is a universal link for this app
    public var isUniversalLink: @Sendable (_ url: URL) -> Bool = { _ in false }
    
    /// Check if the URL is a custom scheme for this app
    public var isCustomScheme: @Sendable (_ url: URL) -> Bool = { _ in false }
    
    /// Handle incoming deep link (returns true if handled)
    public var handleDeepLink: @Sendable (_ url: URL) async -> Bool = { _ in false }
    
    /// Store a deferred deep link for first-launch routing
    public var saveDeferredDeepLink: @Sendable (_ url: URL, _ source: DeferredDeepLink.Source) async -> Void = { _, _ in }
    
    /// Retrieve and clear deferred deep link (if any)
    public var consumeDeferredDeepLink: @Sendable () async -> DeferredDeepLink? = { nil }
    
    /// Check if there's a pending deferred deep link
    public var hasDeferredDeepLink: @Sendable () async -> Bool = { false }
}

// MARK: - Live Implementation

extension DeepLinkClient: DependencyKey {
    public static let liveValue: Self = {
        let storage = DeferredDeepLinkStorage()
        let logger = Logger(subsystem: "com.axiomorient.awesomeapp", category: "DeepLink")
        
        return Self(
            parse: { url in
                DeepLinkParser.parse(url)
            },
            isUniversalLink: { url in
                DeepLinkParser.isUniversalLink(url)
            },
            isCustomScheme: { url in
                DeepLinkParser.isCustomScheme(url)
            },
            handleDeepLink: { url in
                let route = DeepLinkParser.parse(url)
                logger.info("🔗 Deep link received: \(url.absoluteString) → \(String(describing: route))")
                
                if case .unknown = route {
                    logger.warning("⚠️ Unhandled deep link path")
                    return false
                }
                return true
            },
            saveDeferredDeepLink: { url, source in
                let deferred = DeferredDeepLink(url: url, source: source)
                await storage.save(deferred)
                logger.info("💾 Deferred deep link saved: \(url.absoluteString)")
            },
            consumeDeferredDeepLink: {
                guard let deferred = await storage.load() else { return nil }
                await storage.clear()
                logger.info("📤 Deferred deep link consumed: \(deferred.url.absoluteString)")
                return deferred
            },
            hasDeferredDeepLink: {
                await storage.load() != nil
            }
        )
    }()
}

// MARK: - Deferred Deep Link Storage

private actor DeferredDeepLinkStorage {
    private let key = "awesomeapp.deferredDeepLink"
    private let defaults = UserDefaults.standard
    
    func save(_ deferred: DeferredDeepLink) {
        guard let data = try? JSONEncoder().encode(deferred) else { return }
        defaults.set(data, forKey: key)
    }
    
    func load() -> DeferredDeepLink? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(DeferredDeepLink.self, from: data)
    }
    
    func clear() {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Dependency Registration

public extension DependencyValues {
    var deepLink: DeepLinkClient {
        get { self[DeepLinkClient.self] }
        set { self[DeepLinkClient.self] = newValue }
    }
}
