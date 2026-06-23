import SwiftUI
import SwiftData
import RevenueCatUI

/// Flow: onboarding (once) -> the app.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var purchases: PurchaseManager
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.isEmpty {
                NavigationStack { OnboardingView() }
            } else if !purchases.isReady {
                loadingView
            } else if purchases.isSubscribed {
                MainTabView()
            } else {
                revenueCatPaywall
            }
        }
        .task { await purchases.start() }
        #if DEBUG
        .task { seedForDevIfRequested() }
        #endif
    }

    private var loadingView: some View {
        ScreenContainer {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Theme.surface.opacity(0.72))
                        .frame(width: 96, height: 96)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(Theme.accentFill.opacity(0.22), lineWidth: 1)
                        )
                    EdenLoadingMark(size: 58)
                }

                Text("Eden")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
