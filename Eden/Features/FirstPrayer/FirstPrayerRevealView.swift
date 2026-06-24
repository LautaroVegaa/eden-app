import SwiftUI
import SwiftData

/// The one free, personalized prayer shown right after onboarding — the value
/// "aha" the onboarding promised. After the user reads it, the hard paywall
/// gates everything else. Generates once and caches it as today's prayer, so it
/// carries seamlessly into Today after the user subscribes.
struct FirstPrayerRevealView: View {
    let profile: UserProfile
    let onContinue: () -> Void

    @Environment(\.modelContext) private var modelContext

    private enum Phase {
        case generating
        case loaded(body: String, verseReference: String, verseText: String)
        case failed
    }

    @State private var phase: Phase = .generating
    @State private var revealed = false

    var body: some View {
        ScreenContainer {
            ScrollView {
                VStack(spacing: 22) {
                    switch phase {
                    case .generating:
                        generatingState
                    case let .loaded(body, reference, verseText):
                        loadedState(body: body, reference: reference, verseText: verseText)
                    case .failed:
                        failedState
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .task { await generate() }
    }

    private var generatingState: some View {
        VStack(spacing: 18) {
            ProgressView()
                .controlSize(.large)
                .tint(Theme.accentText)
            Text("Writing your first prayer…")
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 120)
    }

    private func loadedState(body: String, reference: String, verseText: String) -> some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("Your first prayer")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(Theme.accentText)
                Text(profile.name.isEmpty ? "Made for you" : "Made for you, \(profile.name)")
                    .font(.system(.title2, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
            }

            if !verseText.isEmpty {
                VerseCard(reference: reference, text: verseText)
            }

            Text(body)
                .font(.system(.title3, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))

            Button("Continue", action: onContinue)
                .buttonStyle(EdenPrimaryButtonStyle())
                .padding(.top, 4)
        }
        .opacity(revealed ? 1 : 0)
        .offset(y: revealed ? 0 : 14)
        .onAppear { withAnimation(.easeOut(duration: 0.55)) { revealed = true } }
    }

    private var failedState: some View {
        VStack(spacing: 16) {
            Text("We couldn't finish your prayer right now.")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Your connection may have dropped. You can keep going.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Button("Try again") { Task { await generate() } }
                .buttonStyle(.bordered)
                .tint(Theme.accentText)
            Button("Continue", action: onContinue)
                .buttonStyle(EdenPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 90)
    }

    // MARK: - Generation

    private func generate() async {
        phase = .generating
        revealed = false
        let struggle = profile.struggle ?? ""
        let note = profile.confession
        let verse = VerseStore.shared.verse(for: "\(struggle) \(note)")
        let request = PrayerRequest(
            name: profile.name,
            gender: profile.gender ?? "",
            struggle: struggle,
            desire: profile.desire ?? "peace",
            freeText: note,
            verseReference: verse?.reference ?? "",
            verseText: verse?.text ?? ""
        )
        do {
            let text = try await PrayerService().generatePrayer(request)
            let body = stripTrailingVerse(text)
            cacheIfAbsent(text, verse: verse, struggle: struggle)
            WidgetVerseStore.save(reference: verse?.reference ?? "", text: verse?.text ?? "")
            HapticService.success()
            phase = .loaded(body: body, verseReference: verse?.reference ?? "", verseText: verse?.text ?? "")
        } catch PrayerServiceError.notAllowed {
            // Free prayer already spent (e.g. reinstall, where the server remembers
            // but the local flag reset) or not eligible — move on to the paywall
            // instead of showing a misleading "connection dropped" error.
            onContinue()
        } catch {
            phase = .failed
        }
    }

    /// Cache as today's prayer so it appears on Today after the user subscribes —
    /// without a second Worker call. No-op if a prayer for today already exists.
    private func cacheIfAbsent(_ text: String, verse: Verse?, struggle: String) {
        let key = DayKey.key()
        let descriptor = FetchDescriptor<DailyPrayer>(predicate: #Predicate { $0.dateKey == key })
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty { return }
        modelContext.insert(DailyPrayer(
            dateKey: key,
            prayerText: text,
            struggle: struggle,
            verseReference: verse?.reference ?? "",
            verseText: verse?.text ?? ""
        ))
        try? modelContext.save()
    }

    /// Drop a trailing "Reference 1:1" line if the model appended the verse, so
    /// it isn't shown twice (verse card + body).
    private func stripTrailingVerse(_ text: String) -> String {
        let lines = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard let last = lines.last,
              last.count < 40, last.contains(":"),
              last.rangeOfCharacter(from: .decimalDigits) != nil else { return text }
        let body = lines.dropLast().joined(separator: "\n\n")
        return body.isEmpty ? text : body
    }
}
