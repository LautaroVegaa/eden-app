import SwiftUI
import RevenueCatUI

struct MainTabView: View {
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage(AppConfig.hasSeenFirstPrayerKey) private var hasSeenFirstPrayer = false
    @State private var selectedTab: MainTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }
            .tag(MainTab.today)

            NavigationStack {
                TalkToGodView {
                    selectedTab = .today
                }
            }
            .tabItem {
                Label("Pray", systemImage: "sparkles")
            }
            .tag(MainTab.talk)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(MainTab.profile)
        }
        .tint(Theme.accentText)
        .onChange(of: selectedTab) { _, _ in
            HapticService.selection()
        }
        .task {
            // Returning non-subscribers who already spent their free prayer see the
            // paywall on launch. Within the first session we do NOT slam it on top of
            // the free prayer — the user must be able to read (the aha). The paywall
            // then triggers on the next paid action (new prayer, chat, Listen).
            if !purchases.isSubscribed && hasSeenFirstPrayer { purchases.showPaywall = true }
        }
        .fullScreenCover(isPresented: $purchases.showPaywall) {
            paywallCover
        }
    }

    private var paywallCover: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                purchases.apply(customerInfo)
            }
            .onRestoreCompleted { customerInfo in
                purchases.apply(customerInfo)
            }
            .ignoresSafeArea()
    }

    private enum MainTab: Hashable {
        case today
        case talk
        case profile
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
