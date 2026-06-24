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
        case .frequency:
            OnboardingSingleSelect(
                title: "How often does the anxiety hit?",
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
                options: [
                    "\"Cast all your anxiety on him, because he cares for you.\" 1 Peter 5:7",
                    "\"Be still, and know that I am God.\" Psalm 46:10",
                    "\"When anxiety was great within me, your consolation brought me joy.\" Psalm 94:19"
                ],
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
