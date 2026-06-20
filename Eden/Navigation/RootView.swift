import SwiftUI
import SwiftData

/// Onboarding once, then the daily app. If a profile exists, the user has
/// finished onboarding and lands on Today.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.isEmpty {
                NavigationStack { OnboardingView() }
            } else {
                MainTabView()
            }
        }
        #if DEBUG
        .task { seedForDevIfRequested() }
        #endif
    }

    #if DEBUG
    // Dev-only: launch with SIMCTL_CHILD_EDEN_SEED=1 to skip onboarding and land
    // straight on Today with a test profile. No effect in release builds.
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

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
