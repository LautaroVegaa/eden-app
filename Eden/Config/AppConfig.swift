import Foundation

enum AppConfig {
    /// The Cloudflare Worker that proxies prayer generation. Public by design —
    /// the secret (Anthropic key) lives inside the Worker, never here.
    static let prayerEndpoint = URL(string: "https://eden-prayer.lautarocarignani.workers.dev")!
}
