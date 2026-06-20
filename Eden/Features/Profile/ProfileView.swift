import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let profile {
                        profileSummary(profile)
                        streakSummary(profile)
                        prayerSchedule(profile)
                    } else {
                        emptyState
                    }

                    MedicalDisclaimerText()
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Profile")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Your prayer rhythm, kept on this iPhone.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private func profileSummary(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileRow(icon: "person.fill", title: "Name", value: profile.name.isEmpty ? "Not set" : profile.name)
            ProfileRow(icon: "heart.fill", title: "Main weight", value: profile.struggle ?? "Not set")
            ProfileRow(icon: "sparkles", title: "Praying for", value: profile.desire ?? "Peace")
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func streakSummary(_ profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            ProfileMetric(icon: "flame.fill", value: "\(profile.currentStreak)", label: "Current streak")
            ProfileMetric(icon: "trophy.fill", value: "\(profile.longestStreak)", label: "Longest streak")
        }
    }

    private func prayerSchedule(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ProfileRow(
                icon: "bell.fill",
                title: "Daily prayer",
                value: profile.mindRaceTime.map(Self.timeFormatter.string(from:)) ?? "Not scheduled"
            )
            Text("Notification permission is controlled in iOS Settings.")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyState: some View {
        Text("Finish onboarding to build your profile.")
            .font(.subheadline)
            .foregroundStyle(Theme.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            GlassSymbolBadge(systemName: icon)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

private struct ProfileMetric: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GlassSymbolBadge(systemName: icon)
            Text(value)
                .font(.system(.title, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct GlassSymbolBadge: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.accent)
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Theme.accent.opacity(0.22), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
