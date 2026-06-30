import SwiftUI
import SwiftData
import RevenueCat

struct ProfileView: View {
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @Environment(\.colorScheme) private var systemColorScheme
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage(HapticService.enabledKey) private var hapticsEnabled = true
    @AppStorage(AppAppearance.storageKey) private var appearanceMode = AppAppearance.system.rawValue
    @State private var showingEdit = false
    @State private var isRestoringPurchases = false
    @State private var subscriptionMessage: String?
    @State private var showingDeleteConfirmation = false
    @State private var isDeletingCloudData = false
    @State private var privacyMessage: String?

    private var profile: UserProfile? { profiles.first }
    private var appearance: AppAppearance { AppAppearance(rawValue: appearanceMode) ?? .system }
    private var isDarkMode: Binding<Bool> {
        Binding(
            get: {
                if appearance == .system { return systemColorScheme == .dark }
                return appearance == .dark
            },
            set: { appearanceMode = $0 ? AppAppearance.dark.rawValue : AppAppearance.light.rawValue }
        )
    }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let profile {
                        profileSummary(profile)
                        streakSummary(profile)
                        prayerSchedule(profile)
                        subscriptionCard
                        settingsCard
                        privacyDataCard
                        legalCard
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let profile { EditProfileView(profile: profile) }
        }
        .confirmationDialog(
            "Delete Eden cloud data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete cloud data", role: .destructive) {
                Task { await deleteCloudData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes Eden's usage ledger, App Attest registration, and RevenueCat customer record. It does not cancel an Apple subscription or delete prayers stored on this iPhone.")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Your prayer rhythm, kept on this iPhone.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
            if profile != nil {
                Button("Edit") {
                    HapticService.selection()
                    showingEdit = true
                }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accentText)
            }
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

    private var subscriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                GlassSymbolBadge(systemName: purchases.isSubscribed ? "checkmark.seal.fill" : "creditcard.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Subscription")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(purchases.isSubscribed ? "Premium access is active." : "Unlock unlimited prayers, chat, and Listen.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Text(purchases.isSubscribed ? "Premium" : "Free")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(purchases.isSubscribed ? Theme.accentText : Theme.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Theme.accentFill.opacity(purchases.isSubscribed ? 0.16 : 0.08), in: Capsule())
            }

            Divider()
                .overlay(Theme.textMuted.opacity(0.18))

            if !purchases.isSubscribed {
                Button {
                    HapticService.selection()
                    purchases.showPaywall = true
                } label: {
                    ProfileActionRow(
                        icon: "sparkles",
                        title: "See subscription options",
                        subtitle: "Weekly with a 3-day free trial, or yearly"
                    )
                }
                .buttonStyle(.plain)
            }

            Button {
                HapticService.selection()
                openURL(AppConfig.manageSubscriptionsURL)
            } label: {
                ProfileActionRow(
                    icon: "slider.horizontal.3",
                    title: "Manage subscription",
                    subtitle: "Change or cancel from your Apple account"
                )
            }
            .buttonStyle(.plain)

            Button {
                Task { await restorePurchases() }
            } label: {
                ProfileActionRow(
                    icon: isRestoringPurchases ? "arrow.triangle.2.circlepath" : "arrow.clockwise",
                    title: isRestoringPurchases ? "Restoring purchases" : "Restore purchases",
                    subtitle: "Use this if you already subscribed"
                )
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases)

            if let subscriptionMessage {
                Text(subscriptionMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.2), value: subscriptionMessage)
    }

    private var legalCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                GlassSymbolBadge(systemName: "doc.text.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Legal & support")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("AI processing and World English Bible (WEB) sources are documented here.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
            }

            Divider().overlay(Theme.textMuted.opacity(0.18))

            Button { openURL(AppConfig.privacyPolicyURL) } label: {
                ProfileActionRow(icon: "lock.shield", title: "Privacy Policy", subtitle: "How your data is used and shared")
            }
            .buttonStyle(.plain)

            Button { openURL(AppConfig.termsURL) } label: {
                ProfileActionRow(icon: "doc.plaintext", title: "Terms of Use", subtitle: "The agreement for using Eden")
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var privacyDataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                GlassSymbolBadge(systemName: "hand.raised.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Privacy & data")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Manage the data Eden keeps for you.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
            }

            Divider().overlay(Theme.textMuted.opacity(0.18))

            Button {
                showingDeleteConfirmation = true
            } label: {
                ProfileActionRow(
                    icon: isDeletingCloudData ? "arrow.triangle.2.circlepath" : "trash",
                    title: isDeletingCloudData ? "Deleting cloud data" : "Delete cloud data",
                    subtitle: "Erase Eden and RevenueCat server records"
                )
            }
            .buttonStyle(.plain)
            .disabled(isDeletingCloudData)

            Button { openURL(privacySupportURL) } label: {
                ProfileActionRow(
                    icon: "envelope",
                    title: "Privacy support",
                    subtitle: "Request help with access or deletion"
                )
            }
            .buttonStyle(.plain)

            if let privacyMessage {
                Text(privacyMessage)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                GlassSymbolBadge(systemName: "circle.lefthalf.filled")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dark mode")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(appearance == .system ? "Following this iPhone." : "Set manually.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Toggle("", isOn: isDarkMode)
                    .labelsHidden()
                    .tint(Theme.accentFill)
            }

            if appearance != .system {
                Button("Use iPhone setting") {
                    HapticService.selection()
                    appearanceMode = AppAppearance.system.rawValue
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accentText)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .overlay(Theme.textMuted.opacity(0.18))

            HStack(spacing: 12) {
                GlassSymbolBadge(systemName: "hand.tap.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Haptic feedback")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Subtle taps on navigation and key actions.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer()
                Toggle("", isOn: $hapticsEnabled)
                    .labelsHidden()
                    .tint(Theme.accentFill)
                    .onChange(of: hapticsEnabled) { _, newValue in
                        if newValue { HapticService.success() }
                    }
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private func streakSummary(_ profile: UserProfile) -> some View {
        HStack(spacing: 12) {
            ProfileMetric(icon: "flame.fill", value: "\(profile.liveCurrentStreak)", label: "Current streak")
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

    @MainActor
    private func restorePurchases() async {
        guard !isRestoringPurchases else { return }
        isRestoringPurchases = true
        subscriptionMessage = nil
        HapticService.selection()

        do {
            try await purchases.restore()
            if purchases.isSubscribed {
                HapticService.success()
                subscriptionMessage = "Purchases restored. Premium is active."
            } else {
                subscriptionMessage = "Restore completed. No active subscription was found for this Apple ID."
            }
        } catch {
            subscriptionMessage = "Couldn't restore purchases. Check your connection and try again."
        }

        isRestoringPurchases = false
    }

    @MainActor
    private func deleteCloudData() async {
        guard !isDeletingCloudData else { return }
        isDeletingCloudData = true
        privacyMessage = nil
        HapticService.selection()

        do {
            try await DataPrivacyService().deleteCloudData()
            purchases.markCustomerDataDeleted()
            HapticService.success()
            privacyMessage = "Cloud data deleted. Prayers stored on this iPhone remain until you delete the app."
        } catch {
            privacyMessage = error.localizedDescription
        }
        isDeletingCloudData = false
    }

    private var privacySupportURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "edensupport@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Eden privacy request"),
            URLQueryItem(
                name: "body",
                value: "Please help with my privacy request. My anonymous Eden identifier is: \(Purchases.shared.appUserID)"
            ),
        ]
        return components.url ?? AppConfig.supportEmailURL
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private struct ProfileActionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accentText)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.textMuted.opacity(0.75))
        }
        .contentShape(Rectangle())
    }
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
            .foregroundStyle(Theme.accentText)
            .frame(width: 38, height: 38)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(
                Circle()
                    .strokeBorder(Theme.accentText.opacity(0.22), lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack { ProfileView() }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
        .environmentObject(PurchaseManager())
}
