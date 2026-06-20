import Foundation
import UserNotifications

final class PrayerNotificationService {
    static let shared = PrayerNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let dailyPrayerIdentifier = "eden.daily-prayer"

    private init() {}

    func requestAndScheduleDailyPrayer(at time: Date) async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else { return false }
            await scheduleDailyPrayer(at: time)
            return true
        } catch {
            return false
        }
    }

    func scheduleDailyPrayer(at time: Date) async {
        center.removePendingNotificationRequests(withIdentifiers: [dailyPrayerIdentifier])

        let calendar = Calendar.current
        var components = calendar.dateComponents([.hour, .minute], from: time)
        components.second = 0

        let content = UNMutableNotificationContent()
        content.title = "Your prayer is ready"
        content.body = "Take one minute with God before your mind starts racing."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: dailyPrayerIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }
}
