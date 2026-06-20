import Foundation

/// In-memory answers collected while the user moves through onboarding.
/// Persisted to a UserProfile only when the flow finishes.
struct OnboardingDraft {
    var struggle: String?
    var frequency: String?
    var distance: String?
    var wordsStruggle: String?
    var mindRaceTime: Date?
    var desire: String?
    var verse: String?
    var gender: String?
    var name: String = ""
    var confession: String = ""
}
