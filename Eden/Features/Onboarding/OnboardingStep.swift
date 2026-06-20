import Foundation

/// Ordered onboarding steps. Drives the progress bar and the flow order.
/// Copy for each step lives in OnboardingContainer for easy iteration.
enum OnboardingStep: Int, CaseIterable {
    case pain
    case frequency
    case distance
    case words
    case mindRace
    case beat
    case desire
    case verse
    case gender
    case name
    case confession
    case notifications
}
