import SwiftUI
import RevenueCatUI

struct MainTabView: View {
    @EnvironmentObject private var purchases: PurchaseManager
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
                Label("Talk", systemImage: "sparkles")
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
            // Greet non-subscribers (limited mode) with the paywall on entry.
            if !purchases.isSubscribed { purchases.showPaywall = true }
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
