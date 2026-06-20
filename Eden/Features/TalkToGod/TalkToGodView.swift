import SwiftUI
import SwiftData

struct TalkToGodView: View {
    @Query(sort: \UserProfile.createdAt, order: .reverse) private var profiles: [UserProfile]
    @StateObject private var speaker = PrayerSpeaker()
    @State private var input = ""
    @State private var phase: Phase = .idle
    @State private var remaining = TalkPrayerLocalStore.dailyLimit
    @FocusState private var focused: Bool

    private enum Phase {
        case idle
        case loading
        case loaded(prayer: String, verseReference: String, verseText: String, cached: Bool)
        case failed(String)
    }

    private var profile: UserProfile? { profiles.first }
    private var trimmedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    inputCard
                    generateButton
                    phaseView
                    MedicalDisclaimerText()
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .onAppear { refreshRemaining() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Talk to God")
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("Write what is weighing on you. Eden will turn it into a short prayer.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if input.isEmpty {
                    Text("e.g. I have an exam tomorrow and I feel panicked...")
                        .font(.body)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                }

                TextEditor(text: $input)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 150)
                    .focused($focused)
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))

            Text("\(remaining) guided prayer\(remaining == 1 ? "" : "s") left today")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generatePrayer() }
        } label: {
            if case .loading = phase {
                ProgressView()
                    .tint(Theme.onAccent)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Write My Prayer")
            }
        }
        .buttonStyle(EdenPrimaryButtonStyle())
        .disabled(trimmedInput.isEmpty || isLoading)
        .opacity(trimmedInput.isEmpty || isLoading ? 0.6 : 1.0)
    }

    @ViewBuilder
    private var phaseView: some View {
        switch phase {
        case .idle:
            EmptyView()
        case .loading:
            loadingCard
        case let .loaded(prayer, verseReference, verseText, cached):
            VStack(alignment: .leading, spacing: 18) {
                if cached {
                    Label("Saved for today", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textMuted)
                }
                VerseCard(reference: verseReference, text: verseText)
                PrayerCard(
                    body_: prayer,
                    isSpeaking: speaker.isSpeaking,
                    onToggleListen: { speaker.toggle(prayer) },
                    shareImage: nil
                )
            }
        case let .failed(message):
            errorCard(message)
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Theme.accent)
            Text("Writing your prayer...")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func errorCard(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(Theme.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var isLoading: Bool {
        if case .loading = phase { return true }
        return false
    }

    private func generatePrayer() async {
        let prompt = trimmedInput
        guard !prompt.isEmpty else { return }
        guard let profile else {
            phase = .failed("Finish onboarding first.")
            return
        }

        let dayKey = DayKey.key()
        if let cached = TalkPrayerLocalStore.shared.cachedPrayer(for: prompt, dayKey: dayKey) {
            phase = .loaded(
                prayer: cached.prayer,
                verseReference: cached.verseReference,
                verseText: cached.verseText,
                cached: true
            )
            refreshRemaining()
            return
        }

        guard TalkPrayerLocalStore.shared.canGenerate(dayKey: dayKey) else {
            phase = .failed("You have used today's guided prayers. Come back tomorrow.")
            refreshRemaining()
            return
        }

        phase = .loading
        let struggle = profile.struggle ?? "anxiety"
        let verse = VerseStore.shared.verse(for: "\(prompt) \(struggle)")
        let request = PrayerRequest(
            name: profile.name,
            gender: profile.gender ?? "",
            struggle: struggle,
            desire: profile.desire ?? "peace",
            freeText: prompt,
            verseReference: verse?.reference ?? "",
            verseText: verse?.text ?? ""
        )

        do {
            let text = try await PrayerService().generatePrayer(request)
            let body = stripTrailingVerse(text)
            TalkPrayerLocalStore.shared.save(
                prompt: prompt,
                prayer: body,
                verseReference: verse?.reference ?? "",
                verseText: verse?.text ?? "",
                dayKey: dayKey
            )
            phase = .loaded(
                prayer: body,
                verseReference: verse?.reference ?? "",
                verseText: verse?.text ?? "",
                cached: false
            )
            refreshRemaining()
        } catch {
            phase = .failed("Couldn't write your prayer. Check your connection and try again.")
            refreshRemaining()
        }
    }

    private func refreshRemaining() {
        remaining = TalkPrayerLocalStore.shared.remainingGenerations()
    }

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
}

#Preview {
    NavigationStack { TalkToGodView() }
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
