import Foundation

struct TalkPrayerCacheEntry: Codable {
    let dayKey: String
    let prompt: String
    let prayer: String
    let verseReference: String
    let verseText: String
    let createdAt: Date
}

final class TalkPrayerLocalStore {
    static let shared = TalkPrayerLocalStore()
    static let dailyLimit = 3

    private let storageKey = "eden.talkPrayer.cache.v1"
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func cachedPrayer(for prompt: String, dayKey: String = DayKey.key()) -> TalkPrayerCacheEntry? {
        let normalized = normalize(prompt)
        return entries().first {
            $0.dayKey == dayKey && normalize($0.prompt) == normalized
        }
    }

    func remainingGenerations(dayKey: String = DayKey.key()) -> Int {
        max(0, Self.dailyLimit - generatedCount(dayKey: dayKey))
    }

    func canGenerate(dayKey: String = DayKey.key()) -> Bool {
        remainingGenerations(dayKey: dayKey) > 0
    }

    func save(prompt: String, prayer: String, verseReference: String, verseText: String, dayKey: String = DayKey.key()) {
        var current = entries()
        current.removeAll {
            $0.dayKey == dayKey && normalize($0.prompt) == normalize(prompt)
        }
        current.append(TalkPrayerCacheEntry(
            dayKey: dayKey,
            prompt: prompt,
            prayer: prayer,
            verseReference: verseReference,
            verseText: verseText,
            createdAt: Date()
        ))
        save(current)
    }

    private func generatedCount(dayKey: String) -> Int {
        entries().filter { $0.dayKey == dayKey }.count
    }

    private func entries() -> [TalkPrayerCacheEntry] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TalkPrayerCacheEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    private func save(_ entries: [TalkPrayerCacheEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func normalize(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
