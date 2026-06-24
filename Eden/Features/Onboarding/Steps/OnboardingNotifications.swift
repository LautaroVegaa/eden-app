import SwiftUI

/// Emotional notification priming before the real iOS permission prompt. Also the
/// last onboarding step everyone passes, so it carries the AI-sharing consent —
/// guaranteeing it is granted before any prayer or chat data is ever sent.
struct OnboardingNotifications: View {
    let onDecision: (Bool) -> Void

    @AppStorage(AppConfig.aiConsentKey) private var aiConsentGranted = false
    @Environment(\.openURL) private var openURL
    @State private var aiSharingAccepted = false

    private func proceed(_ allow: Bool) {
        guard aiSharingAccepted else { return }
        aiConsentGranted = true
        onDecision(allow)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accentText)
                    .padding(.top, 40)
                    .padding(.bottom, 8)
                Text("One prayer, right when you need it.")
                    .font(.system(.title, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Can we send you a prayer at the hour your mind races most?")
                    .font(.body)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)

                aiConsentDisclosure

                Toggle(isOn: $aiSharingAccepted) {
                    Text("I agree to this AI data sharing.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.accentFill)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))

                VStack(spacing: 12) {
                    Button("Allow notifications") { proceed(true) }
                        .buttonStyle(EdenPrimaryButtonStyle())
                    Button("Maybe later") { proceed(false) }
                        .font(.edenButton)
                        .foregroundStyle(Theme.textMuted)
                }
                .disabled(!aiSharingAccepted)
                .opacity(aiSharingAccepted ? 1 : 0.55)

                MedicalDisclaimerText()
                    .padding(.top, 6)
            }
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
    }

    /// Apple 5.1.1/5.1.2: explicit consent before sharing personal content with a
    /// third-party AI, obtained before the user reaches any prayer or chat.
    private var aiConsentDisclosure: some View {
        VStack(spacing: 4) {
            Text("Eden sends your first name and what you share through its secure server to Anthropic (Claude AI) to create prayers and replies. If you use Listen, Eden sends the generated prayer to OpenAI to create temporary audio. Eden does not store your prayer text or audio on its servers.")
                .font(.caption2)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.accentText)
        }
    }
}
