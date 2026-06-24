import SwiftUI
import SwiftData

/// Drives the onboarding flow: progress bar on top, one step at a time.
/// All step copy lives here for easy iteration. Answers accumulate in `draft`
/// and are saved to a UserProfile when the flow finishes.
struct OnboardingContainer: View {
    var onFinished: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @State private var stepIndex = 0
    @State private var draft = OnboardingDraft()
    private let steps = OnboardingStep.allCases

    /// The user's chosen struggle as a natural phrase, so follow-up questions read
    /// like a person wrote them ("How often does the loneliness hit?") instead of
    /// hardcoding "anxiety". Falls back to "it" where a noun would read awkwardly.
    private var struggleNoun: String {
        switch draft.struggle {
        case "Anxiety": return "the anxiety"
        case "Fear about the future": return "the fear"
        case "Loneliness": return "the loneliness"
        case "Doubt": return "the doubt"
        default: return "it"
        }
    }

    /// Three verses that actually fit the struggle the user chose, so the verse
    /// step feels picked for them instead of a generic anxiety list.
    private var verseOptions: [String] {
        switch draft.struggle {
        case "Fear about the future":
            return [
                "\"For I know the thoughts that I think toward you, thoughts of peace and not of evil, to give you hope and a future.\" Jeremiah 29:11",
                "\"Don’t you be afraid, for I am with you. Don’t be dismayed, for I am your God.\" Isaiah 41:10",
                "\"Haven’t I commanded you? Be strong and courageous. Don’t be afraid. Don’t be dismayed, for the Lord your God is with you wherever you go.\" Joshua 1:9"
            ]
        case "Loneliness":
            return [
                "\"The Lord your God himself goes with you. He will not fail you nor forsake you.\" Deuteronomy 31:6",
                "\"The Lord is near to those who have a broken heart, and saves those who have a crushed spirit.\" Psalm 34:18",
                "\"Behold, I am with you always, even to the end of the age.\" Matthew 28:20"
            ]
        case "Doubt":
            return [
                "\"I believe. Help my unbelief!\" Mark 9:24",
                "\"Trust in the Lord with all your heart, and don’t lean on your own understanding.\" Proverbs 3:5-6",
                "\"Now faith is assurance of things hoped for, proof of things not seen.\" Hebrews 11:1"
            ]
        case "Relationships":
            return [
                "\"Love is patient and is kind. Love doesn’t envy. Love doesn’t brag, is not proud.\" 1 Corinthians 13:4-5",
                "\"Bear with one another, and forgive each other, if anyone has a complaint against another.\" Colossians 3:13",
                "\"If it is possible, as much as it is up to you, be at peace with all men.\" Romans 12:18"
            ]
        default: // Anxiety
            return [
                "\"Casting all your worries on him, because he cares for you.\" 1 Peter 5:7",
                "\"Be still, and know that I am God. I will be exalted among the nations.\" Psalm 46:10",
                "\"In the multitude of my thoughts within me, your comforts delight my soul.\" Psalm 94:19"
            ]
        }
    }

    var body: some View {
        ScreenContainer {
            VStack(spacing: 0) {
                OnboardingProgressBar(
                    progress: Double(stepIndex + 1) / Double(steps.count)
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)

                stepView
                    .id(stepIndex)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch steps[stepIndex] {
        case .pain:
            OnboardingSingleSelect(
                title: "What's weighing on you most right now?",
                subtitle: "This shapes every prayer we write for you.",
                options: ["Anxiety", "Fear about the future", "Loneliness", "Doubt", "Relationships"],
                onSelect: { draft.struggle = $0; advance() }
            )
        case .value:
            OnboardingBeat(
                title: "You won't carry it alone.",
                message: "Eden writes a personal prayer for exactly what you're feeling, and stays with you as a companion you can talk to and find calm with, any time you need.",
                onContinue: advance
            )
        case .frequency:
            OnboardingSingleSelect(
                title: "How often does \(struggleNoun) hit?",
                subtitle: "The more it shows up, the more your daily prayer matters.",
                options: ["Every day", "Most days", "A few times a week", "It comes in waves"],
                onSelect: { draft.frequency = $0; advance() }
            )
        case .distance:
            OnboardingSingleSelect(
                title: "When do you feel furthest from God?",
                subtitle: "We'll meet you exactly there.",
                options: ["Late at night", "When I'm scrolling", "When everything goes wrong", "I'm not sure anymore"],
                onSelect: { draft.distance = $0; advance() }
            )
        case .words:
            OnboardingSingleSelect(
                title: "Do you ever struggle to find the words to pray?",
                subtitle: "If you do, that's exactly what Eden is for.",
                options: ["Yes, always", "Sometimes", "No, I'm good with words"],
                onSelect: { draft.wordsStruggle = $0; advance() }
            )
        case .mindRace:
            OnboardingTimePicker(
                title: "When does your mind race the most?",
                subtitle: "We'll remind you to pray right at that moment.",
                onContinue: { draft.mindRaceTime = $0; advance() }
            )
        case .beat:
            OnboardingBeat(
                title: "You're not the only one awake right now.",
                message: "Thousands of Christians your age feel exactly this tonight.",
                onContinue: advance
            )
        case .desire:
            OnboardingSingleSelect(
                title: "What do you want more of?",
                subtitle: "Your prayers will lean toward this.",
                options: ["Peace", "Confidence", "Faith", "Direction"],
                onSelect: { draft.desire = $0; advance() }
            )
        case .verse:
            OnboardingSingleSelect(
                title: "Which one hits hardest right now?",
                subtitle: "Tap the one your heart needs today.",
                options: verseOptions,
                onSelect: { draft.verse = $0; advance() }
            )
        case .gender:
            OnboardingSingleSelect(
                title: "How did God create you?",
                subtitle: "\"I will give thanks to you, for I am fearfully and wonderfully made.\" Psalm 139:14",
                options: ["I'm a woman", "I'm a man"],
                onSelect: { draft.gender = $0; advance() }
            )
        case .name:
            OnboardingTextInput(
                title: "What should we call you?",
                subtitle: "Your prayers will be written just for you, by name.",
                placeholder: "Your name",
                buttonTitle: "Continue",
                onContinue: { draft.name = $0; advance() }
            )
        case .notifications:
            OnboardingNotifications(onDecision: handleNotificationDecision)
        }
    }

    private func advance() {
        if stepIndex < steps.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                stepIndex += 1
            }
        } else {
            saveAndFinish()
        }
    }

    private func handleNotificationDecision(_ shouldSchedule: Bool) {
        Task {
            if shouldSchedule, let time = draft.mindRaceTime {
                _ = await PrayerNotificationService.shared.requestAndScheduleDailyPrayer(at: time)
            }
            await MainActor.run { advance() }
        }
    }

    private func saveAndFinish() {
        let profile = UserProfile(
            name: draft.name,
            gender: draft.gender,
            struggle: draft.struggle,
            frequency: draft.frequency,
            distance: draft.distance,
            wordsStruggle: draft.wordsStruggle,
            desire: draft.desire,
            verse: draft.verse,
            mindRaceTime: draft.mindRaceTime,
            confession: draft.confession
        )
        modelContext.insert(profile)
        try? modelContext.save()
        onFinished()
    }
}
