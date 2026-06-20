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
}
