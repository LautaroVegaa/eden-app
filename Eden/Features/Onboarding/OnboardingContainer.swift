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
                "\"For I know the plans I have for you, plans to prosper you and not to harm you.\" Jeremiah 29:11",
                "\"Do not fear, for I am with you; do not be dismayed, for I am your God.\" Isaiah 41:10",
                "\"Be strong and courageous. Do not be afraid, for the Lord your God will be with you wherever you go.\" Joshua 1:9"
            ]
        case "Loneliness":
            return [
                "\"He will never leave you nor forsake you.\" Deuteronomy 31:6",
                "\"The Lord is close to the brokenhearted and saves those who are crushed in spirit.\" Psalm 34:18",
                "\"Surely I am with you always, to the very end of the age.\" Matthew 28:20"
            ]
        case "Doubt":
            return [
                "\"I do believe; help me overcome my unbelief.\" Mark 9:24",
                "\"Trust in the Lord with all your heart and lean not on your own understanding.\" Proverbs 3:5",
                "\"Now faith is confidence in what we hope for and assurance about what we do not see.\" Hebrews 11:1"
            ]
        case "Relationships":
            return [
                "\"Love is patient, love is kind.\" 1 Corinthians 13:4",
                "\"Bear with each other and forgive one another.\" Colossians 3:13",
                "\"If it is possible, as far as it depends on you, live at peace with everyone.\" Romans 12:18"
            ]
        default: // Anxiety
            return [
                "\"Cast all your anxiety on him, because he cares for you.\" 1 Peter 5:7",
                "\"Be still, and know that I am God.\" Psalm 46:10",
                "\"When anxiety was great within me, your consolation brought me joy.\" Psalm 94:19"
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
                subtitle: "\"I praise you, for I am fearfully and wonderfully made.\" Psalm 139:14",
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
        case .confession:
            OnboardingConfession(onContinue: { draft.confession = $0; advance() })
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
