import Foundation

struct Verse: Decodable, Equatable {
    let reference: String
    let text: String
    let tags: [String]
}

    /// Loads the embedded, curated public-domain World English Bible (WEB)
    /// verse list and picks an
/// accurate "verse of the day" by struggle. This is the source of truth for
/// verse text — the AI is told to use it, never to invent its own.
final class VerseStore {
    static let shared = VerseStore()
    let verses: [Verse]

    private init() {
        if let url = Bundle.main.url(forResource: "verses", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Verse].self, from: data) {
            verses = decoded
        } else {
            verses = []
        }
    }

    func verse(for struggle: String, dayKey: String = DayKey.key()) -> Verse? {
        let t = tag(for: struggle)
        let pool = verses.filter { $0.tags.contains(t) }
        let chosen = pool.isEmpty ? verses : pool
        guard !chosen.isEmpty else { return nil }
        let index = abs(stableHash(dayKey + t)) % chosen.count
        return chosen[index]
    }

    private func tag(for struggle: String) -> String {
        let s = struggle.lowercased()
        if s.contains("lonel") { return "loneliness" }
        if s.contains("doubt") { return "doubt" }
        if s.contains("relationship") { return "relationships" }
        if s.contains("future") { return "future" }
        if s.contains("fear") { return "fear" }
        if s.contains("anx") { return "anxiety" }
        return "peace"
    }

    // Deterministic across launches/days (String.hashValue is randomized).
    private func stableHash(_ s: String) -> Int {
        var h = 5381
        for byte in s.utf8 { h = ((h << 5) &+ h) &+ Int(byte) }
        return h
    }
}
