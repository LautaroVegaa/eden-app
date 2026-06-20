import Foundation
import SwiftData

/// Cached prayer for a given day, so the Worker is called at most once per day.
@Model
final class DailyPrayer {
    var dateKey: String
    var prayerText: String
    var struggle: String
    var verseReference: String
    var verseText: String
    var createdAt: Date

    init(
        dateKey: String,
        prayerText: String,
        struggle: String,
        verseReference: String = "",
        verseText: String = "",
        createdAt: Date = Date()
    ) {
        self.dateKey = dateKey
        self.prayerText = prayerText
        self.struggle = struggle
        self.verseReference = verseReference
        self.verseText = verseText
        self.createdAt = createdAt
    }
}
