import Foundation

/// Local daily cap on Talk to God messages — protects token cost. A chat invites
/// more calls than a one-shot prayer, so we bound it per day (per device).
enum ChatLimiter {
    static let dailyLimit = 20
    private static let dayKeyKey = "eden.chat.day"
    private static let countKey = "eden.chat.count"
    private static var defaults: UserDefaults { .standard }

    static func remaining() -> Int {
        rolloverIfNeeded()
        return max(0, dailyLimit - defaults.integer(forKey: countKey))
    }

    static func canSend() -> Bool { remaining() > 0 }

    static func register() {
        rolloverIfNeeded()
        defaults.set(defaults.integer(forKey: countKey) + 1, forKey: countKey)
    }

    private static func rolloverIfNeeded() {
        let today = DayKey.key()
        if defaults.string(forKey: dayKeyKey) != today {
            defaults.set(today, forKey: dayKeyKey)
            defaults.set(0, forKey: countKey)
        }
    }
}
