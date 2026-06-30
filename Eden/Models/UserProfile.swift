import Foundation
import SwiftData

/// Local, on-device profile built during onboarding. Drives prayer
/// personalization. No accounts, no server — everything stays on device.
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var gender: String?
    var struggle: String?
    var frequency: String?
    var distance: String?
    var wordsStruggle: String?
    var desire: String?
    var verse: String?
    var mindRaceTime: Date?
    var confession: String
    var createdAt: Date

    // Streak (local, no backend).
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastPrayedAt: Date?

    init(
        id: UUID = UUID(),
        name: String = "",
        gender: String? = nil,
        struggle: String? = nil,
        frequency: String? = nil,
        distance: String? = nil,
        wordsStruggle: String? = nil,
        desire: String? = nil,
        verse: String? = nil,
        mindRaceTime: Date? = nil,
        confession: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.struggle = struggle
        self.frequency = frequency
        self.distance = distance
        self.wordsStruggle = wordsStruggle
        self.desire = desire
        self.verse = verse
        self.mindRaceTime = mindRaceTime
        self.confession = confession
        self.createdAt = createdAt
    }

    /// The streak as it actually stands today. `currentStreak` is only recomputed
    /// when the user taps "I prayed", so it goes stale the moment a day is missed.
    /// A streak is alive only if the last prayer was today or yesterday; otherwise
    /// it is broken and reads 0 — reflected immediately for display.
    var liveCurrentStreak: Int {
        guard let last = lastPrayedAt else { return 0 }
        let calendar = Calendar.current
        return (calendar.isDateInToday(last) || calendar.isDateInYesterday(last)) ? currentStreak : 0
    }

    /// Persist a broken streak so the stored value matches reality. Call on load.
    /// `longestStreak` is untouched — it is a historical max and never decreases.
    func normalizeStreak() {
        if liveCurrentStreak == 0 && currentStreak != 0 {
            currentStreak = 0
        }
    }
}
