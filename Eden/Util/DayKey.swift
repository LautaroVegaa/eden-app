import Foundation

/// Stable "yyyy-MM-dd" key for "one prayer per day" caching.
enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(for date: Date = Date()) -> String {
        formatter.string(from: date)
    }
}
