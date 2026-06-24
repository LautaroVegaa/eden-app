import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage(AppConfig.hasSeenFirstPrayerKey) private var hasSeenFirstPrayer = false
    @AppStorage(AppConfig.aiConsentKey) private var aiConsentGranted = false
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @StateObject private var speaker = PrayerSpeaker()

    @State private var phase: Phase = .loading
    @State private var shareImage: UIImage?
    @State private var sharePayload: SharePayload?
    @State private var pendingPrayerToSpeak: String?
    @State private var showingListenConsent = false

    private struct SharePayload {
        let prayerSnippet: String
        let verseText: String
        let verseReference: String
    }

    private enum Phase {
        case loading
        case checkIn
        case generating(verseReference: String, verseText: String)
        case loaded(body: String, verseReference: String, verseText: String)
        case failed(String)
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    content
                    MedicalDisclaimerText().padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .task { await loadCached() }
        .toolbar(shouldHideTabBar ? .hidden : .visible, for: .tabBar)
        .animation(.easeInOut(duration: 0.2), value: shouldHideTabBar)
        .onChange(of: colorScheme) { _, _ in
            rebuildShareImage()
        }
        .alert("Allow AI data sharing?", isPresented: $showingListenConsent) {
            Button("Cancel", role: .cancel) { pendingPrayerToSpeak = nil }
            Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
            Button("Allow and listen") {
                aiConsentGranted = true
                if let prayer = pendingPrayerToSpeak {
                    speaker.toggle(prayer)
                }
                pendingPrayerToSpeak = nil
            }
        } message: {
            Text("Listen sends this generated prayer through Eden's server to OpenAI to create temporary audio. Eden does not store the prayer or audio on its servers.")
        }
    }

    private var shouldHideTabBar: Bool {
        switch phase {
        case .loaded:
            return false
        case .loading, .checkIn, .generating, .failed:
            return true
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            loadingCard("Loading your day…")
        case .checkIn:
            DailyCheckInView(name: profile?.name ?? "") { feeling, note in
                Task { await generate(feeling: feeling, note: note) }
            }
        case let .generating(verseReference, verseText):
            VerseCard(reference: verseReference, text: verseText)
            loadingCard("Writing your prayer")
        case let .loaded(prayerBody, verseReference, verseText):
            VerseCard(reference: verseReference, text: verseText)
            PrayerCard(
                body_: prayerBody,
                isSpeaking: speaker.isSpeaking,
                onToggleListen: {
                    if speaker.isSpeaking {
                        speaker.stop()
                    } else if purchases.requireSubscription() {
                        if aiConsentGranted {
                            speaker.toggle(prayerBody)
                        } else {
                            pendingPrayerToSpeak = prayerBody
                            showingListenConsent = true
                        }
                    }
                },
                shareImage: shareImage
            )
            if let profile {
                StreakCard(
                    currentStreak: profile.currentStreak,
                    prayedToday: prayedToday(profile),
                    onPrayed: { registerPrayed(profile) }
                )
            }
        case let .failed(message):
            errorCard(message)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Today's prayer, made for you.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private func loadingCard(_ message: String) -> some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accentText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Button("Try again") { phase = .checkIn }
                .buttonStyle(.bordered)
                .tint(Theme.accentText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = hour < 12 ? "Good morning" : (hour < 18 ? "Good afternoon" : "Good evening")
        let name = profile?.name ?? ""
        return name.isEmpty ? part : "\(part), \(name)"
    }

    // MARK: - Load / generate

    private func loadCached() async {
        guard profile != nil else {
            phase = .failed("Finish onboarding first.")
            return
        }
        if let cached = fetchCachedPrayer(for: DayKey.key()) {
            applyPrayer(cached.prayerText, reference: cached.verseReference, text: cached.verseText)
        } else {
            phase = .checkIn
        }
    }

    private func generate(feeling: String, note: String) async {
        guard let profile else { return }
        // The first prayer is free (the aha). Every prayer after that is a paid
        // action, so gate it behind the paywall.
        if hasSeenFirstPrayer {
            guard purchases.requireSubscription() else { return }
        }
        let verse = VerseStore.shared.verse(for: "\(feeling) \(note)")
        phase = .generating(verseReference: verse?.reference ?? "", verseText: verse?.text ?? "")
        WidgetVerseStore.save(reference: verse?.reference ?? "", text: verse?.text ?? "")
        HapticService.impact()
        let request = PrayerRequest(
            name: profile.name,
            gender: profile.gender ?? "",
            struggle: feeling,
            desire: profile.desire ?? "peace",
            freeText: note,
            verseReference: verse?.reference ?? "",
            verseText: verse?.text ?? ""
        )
        do {
            let text = try await PrayerService().generatePrayer(request)
            cachePrayer(text, dateKey: DayKey.key(), struggle: feeling, verse: verse)
            applyPrayer(text, reference: verse?.reference ?? "", text: verse?.text ?? "")
            hasSeenFirstPrayer = true
        } catch PrayerServiceError.notAllowed {
            // Free prayer already spent server-side (e.g. after reinstall) or not
            // subscribed — mark it and bring up the paywall instead of an error.
            hasSeenFirstPrayer = true
            phase = .checkIn
            purchases.showPaywall = true
        } catch {
            phase = .failed("Couldn't write your prayer. Check your connection and try again.")
        }
    }

    private func applyPrayer(_ prayerText: String, reference: String, text verseText: String) {
        let body = stripTrailingVerse(prayerText)
        let ref = reference.isEmpty ? trailingVerse(prayerText) : reference
        let resolvedVerseText = resolveVerseText(verseText, reference: ref)
        WidgetVerseStore.save(reference: ref, text: resolvedVerseText)
        shareImage = nil
        phase = .loaded(body: body, verseReference: ref, verseText: resolvedVerseText)
        sharePayload = SharePayload(
            prayerSnippet: firstSentence(body),
            verseText: resolvedVerseText,
            verseReference: ref
        )
        rebuildShareImage()
    }

    private func fetchCachedPrayer(for dateKey: String) -> DailyPrayer? {
        let descriptor = FetchDescriptor<DailyPrayer>(predicate: #Predicate { $0.dateKey == dateKey })
        return try? modelContext.fetch(descriptor).first
    }

    private func cachePrayer(_ text: String, dateKey: String, struggle: String, verse: Verse?) {
        modelContext.insert(DailyPrayer(
            dateKey: dateKey,
            prayerText: text,
            struggle: struggle,
            verseReference: verse?.reference ?? "",
            verseText: verse?.text ?? ""
        ))
        try? modelContext.save()
    }

    // MARK: - Streak

    private func prayedToday(_ profile: UserProfile) -> Bool {
        guard let last = profile.lastPrayedAt else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private func registerPrayed(_ profile: UserProfile) {
        let calendar = Calendar.current
        if let last = profile.lastPrayedAt, calendar.isDateInToday(last) { return }
        if let last = profile.lastPrayedAt, calendar.isDateInYesterday(last) {
            profile.currentStreak += 1
        } else {
            profile.currentStreak = 1
        }
        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
        profile.lastPrayedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Text helpers

    private func isVerseLine(_ line: String) -> Bool {
        line.count < 40 && line.contains(":") && line.rangeOfCharacter(from: .decimalDigits) != nil
    }

    private func stripTrailingVerse(_ text: String) -> String {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard let last = lines.last, isVerseLine(last) else { return text }
        let body = lines.dropLast().joined(separator: "\n\n")
        return body.isEmpty ? text : body
    }

    private func trailingVerse(_ text: String) -> String {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        if let last = lines.last, isVerseLine(last) { return last }
        return ""
    }

    private func firstSentence(_ text: String) -> String {
        if let range = text.rangeOfCharacter(from: CharacterSet(charactersIn: ".!?")) {
            return String(text[..<range.upperBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    private func resolveVerseText(_ text: String, reference: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return VerseStore.shared.verses.first { $0.reference == reference }?.text ?? ""
    }

    @MainActor
    private func rebuildShareImage() {
        guard let sharePayload else { return }
        shareImage = makeShareImage(sharePayload)
    }

    @MainActor
    private func makeShareImage(_ payload: SharePayload) -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareCardView(
                prayerSnippet: payload.prayerSnippet,
                verseText: payload.verseText,
                verseReference: payload.verseReference
            )
            .environment(\.colorScheme, colorScheme)
            .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1.0
        return renderer.uiImage
    }
}
