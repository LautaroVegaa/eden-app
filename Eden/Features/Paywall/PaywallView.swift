import SwiftUI
import SwiftData

struct PaywallView: View {
    // TEMP (block 3 verification): shows the saved profile to confirm
    // onboarding persisted to SwiftData. Removed when the real paywall lands.
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]

    var body: some View {
        ScreenContainer {
            VStack(spacing: 12) {
                Spacer()
                Text("Paywall")
                    .edenTitleStyle()
                Text("End of skeleton flow")
                    .edenBodyStyle()

                if let profile = profiles.first {
                    VStack(spacing: 4) {
                        Text("Saved \(profiles.count) profile(s) ✓")
                        Text("name: \(profile.name.isEmpty ? "—" : profile.name)")
                        Text("struggle: \(profile.struggle ?? "—")")
                        Text("desire: \(profile.desire ?? "—")")
                        Text("confession: \(profile.confession.isEmpty ? "—" : profile.confession)")
                            .lineLimit(2)
                    }
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    NavigationStack { PaywallView() }
        .modelContainer(for: UserProfile.self, inMemory: true)
}
