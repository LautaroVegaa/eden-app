import SwiftUI
import SwiftData
import UIKit

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @StateObject private var speaker = PrayerSpeaker()

    @State private var phase: Phase = .loading
    @State private var shareImage: UIImage?

    private enum Phase {
        case loading
        case loaded(body: String, verseReference: String, verseText: String)
        case failed(String)
    }

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    switch phase {
                    case .loading:
                        loadingCard
                    case let .loaded(prayerBody, verseReference, verseText):
                        VerseCard(reference: verseReference, text: verseText)
                        PrayerCard(
                            body_: prayerBody,
                            isSpeaking: speaker.isSpeaking,
                            onToggleListen: { speaker.toggle(prayerBody) },
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

                    MedicalDisclaimerText()
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .task { await loadPrayer() }
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

    private var loadingCard: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.accent)
            Text("Writing your prayer…")
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
            Button("Try again") { Task { await loadPrayer(force: true) } }
                .buttonStyle(.bordered)
                .tint(Theme.accent)
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

    // MARK: - Loading + caching

    private func loadPrayer(force: Bool = false) async {
        guard let profile else {
            phase = .failed("Finish onboarding first.")
            return
        }
        let today = DayKey.key()
        let struggle = profile.struggle ?? "anxiety"
        let verse = VerseStore.shared.verse(for: struggle)

        if !force, let cached = fetchCachedPrayer(for: today) {
            applyPrayer(cached.prayerText, reference: cached.verseReference, text: cached.verseText)
            return
        }

        phase = .loading
        let request = PrayerRequest(
            name: profile.name,
            gender: profile.gender ?? "",
            struggle: struggle,
            desire: profile.desire ?? "peace",
            freeText: profile.confession,
            verseReference: verse?.reference ?? "",
            verseText: verse?.text ?? ""
        )

        do {
            let text = try await PrayerService().generatePrayer(request)
            cachePrayer(text, dateKey: today, struggle: struggle, verse: verse)
            applyPrayer(text, reference: verse?.reference ?? "", text: verse?.text ?? "")
        } catch {
            phase = .failed("Couldn't load your prayer. Check your connection and try again.")
        }
    }

    private func applyPrayer(_ prayerText: String, reference: String, text verseText: String) {
        let body = stripTrailingVerse(prayerText)
        // If we have no curated verse (JSON missing), fall back to the reference
        // the AI placed at the end of the prayer.
        let ref = reference.isEmpty ? trailingVerse(prayerText) : reference
        phase = .loaded(body: body, verseReference: ref, verseText: verseText)
        shareImage = makeShareImage(snippet: firstSentence(body), verse: ref)
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

    @MainActor
    private func makeShareImage(snippet: String, verse: String) -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareCardView(snippet: snippet, verse: verse).frame(width: 1080, height: 1920)
        )
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

#Preview {
    NavigationStack { TodayView() }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
