import SwiftUI
import SwiftData

@main
struct EdenApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self])
    }
}
