import Foundation

enum AppConfig {
    /// The Cloudflare Worker that proxies prayer generation. Public by design —
    /// the secret (Anthropic key) lives inside the Worker, never here.
    static let prayerEndpoint = URL(string: "https://eden-prayer.lautarocarignani.workers.dev")!

    /// App Attest endpoints on the same Worker. Used to prove requests come from a
    /// genuine app instance (anti-abuse for the public endpoint).
    static let attestChallengeEndpoint = URL(string: "https://eden-prayer.lautarocarignani.workers.dev/attest/challenge")!
    static let attestRegisterEndpoint = URL(string: "https://eden-prayer.lautarocarignani.workers.dev/attest/register")!

    /// Text-to-speech endpoint on the Worker (OpenAI "onyx" voice). Returns mp3.
    static let ttsEndpoint = URL(string: "https://eden-prayer.lautarocarignani.workers.dev/tts")!

    /// RevenueCat public SDK key (safe to ship in the app — the secret key lives
    /// only in the Worker for server-side verification).
    static let revenueCatKey = "appl_SRaqynXhWhUFSUkVlsOexTbjDox"

    /// Apple-hosted subscription management. Required for users to cancel or
    /// change plans outside Eden without us handling billing directly.
    static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    // MARK: - Legal (must be live, public HTTPS before App Review)
    // Served from the eden-web repo on the geteden.site domain. These exact URLs
    // must ALSO go in App Store Connect AND the RevenueCat paywall footer
    // (replacing the broken 127.0.0.1 links).
    static let privacyPolicyURL = URL(string: "https://geteden.site/privacy.html")!
    static let termsURL = URL(string: "https://geteden.site/terms.html")!

    /// Set true once the user explicitly accepts that what they share is sent
    /// to Anthropic (AI) through Eden's server. Gates AI requests.
    static let aiConsentKey = "eden.aiConsentGranted"

    /// Set true after the user has seen their one free prayer (the "aha" right
    /// after onboarding). After this, the hard paywall gates everything.
    static let hasSeenFirstPrayerKey = "eden.hasSeenFirstPrayer"
}
