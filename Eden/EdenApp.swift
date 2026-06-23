import SwiftUI
import SwiftData
import RevenueCat

@main
struct EdenApp: App {
    @StateObject private var purchases = PurchaseManager()
    @AppStorage(AppAppearance.storageKey) private var appearanceMode = AppAppearance.system.rawValue

    init() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: AppConfig.revenueCatKey)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(purchases)
                .preferredColorScheme(AppAppearance(rawValue: appearanceMode)?.colorScheme)
        }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self])
    }
}
