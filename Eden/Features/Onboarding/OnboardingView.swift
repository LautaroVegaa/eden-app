import SwiftUI

struct OnboardingView: View {
    var body: some View {
        // On finish, OnboardingContainer saves the profile; RootView observes
        // that and swaps to the Today screen.
        OnboardingContainer()
            .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack { OnboardingView() }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
