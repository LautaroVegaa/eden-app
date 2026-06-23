import SwiftUI
import SwiftData
import RevenueCatUI

/// Flow: splash -> onboarding (once) -> one free prayer -> hard paywall -> app.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchases: PurchaseManager
    @Query private var profiles: [UserProfile]
    @AppStorage(AppConfig.hasSeenFirstPrayerKey) private var hasSeenFirstPrayer = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            content
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task { await purchases.start() }
        .task { await dismissSplashAfterMinimum() }
        #if DEBUG
        .task { seedForDevIfRequested() }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if profiles.isEmpty {
            NavigationStack { OnboardingView() }
        } else if !purchases.isReady {
            SplashView()
        } else if purchases.isSubscribed {
            MainTabView()
        } else if !hasSeenFirstPrayer, let profile = profiles.first {
            FirstPrayerRevealView(profile: profile) {
                HapticService.selection()
                withAnimation(.easeInOut(duration: 0.35)) { hasSeenFirstPrayer = true }
            }
        } else {
            revenueCatPaywall
        }
    }

    /// Hold the splash for a short, deliberate beat so the brand lands and the
    /// subscription state has time to resolve underneath.
    private func dismissSplashAfterMinimum() async {
        try? await Task.sleep(nanoseconds: 1_400_000_000)
        withAnimation(.easeInOut(duration: 0.45)) { showSplash = false }
    }

    private var revenueCatPaywall: some View {
        PaywallView(displayCloseButton: false)
            .onPurchaseCompleted { customerInfo in
                purchases.apply(customerInfo)
            }
            .onRestoreCompleted { customerInfo in
                purchases.apply(customerInfo)
            }
            .ignoresSafeArea()
    }

    #if DEBUG
    // Dev-only: launch with SIMCTL_CHILD_EDEN_SEED=1 to skip onboarding with a
    // test profile. No effect in release builds.
    private func seedForDevIfRequested() {
        guard ProcessInfo.processInfo.environment["EDEN_SEED"] == "1", profiles.isEmpty else { return }
        let profile = UserProfile(
            name: "Lauti",
            gender: "I'm a man",
            struggle: "Anxiety",
            desire: "Peace",
            confession: "I can't sleep, my mind won't stop"
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }
    #endif
}
