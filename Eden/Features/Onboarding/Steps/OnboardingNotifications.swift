import SwiftUI

/// Emotional notification priming before the real iOS permission prompt. Also the
/// last onboarding step everyone passes, so it carries the AI-sharing consent —
/// guaranteeing it is granted before any prayer or chat data is ever sent.
struct OnboardingNotifications: View {
    let onDecision: (Bool) -> Void

    @AppStorage(AppConfig.aiConsentKey) private var aiConsentGranted = false
    @Environment(\.openURL) private var openURL

    private func proceed(_ allow: Bool) {
        aiConsentGranted = true
        onDecision(allow)
    }

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accentText)
                .padding(.bottom, 8)
            Text("One prayer, right when you need it.")
                .font(.system(.title, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text("Can we send you a prayer at the hour your mind races most?")
                .font(.body)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
            VStack(spacing: 12) {
                Button("Allow") { proceed(true) }
                    .buttonStyle(EdenPrimaryButtonStyle())
                Button("Maybe later") { proceed(false) }
                    .font(.edenButton)
                    .foregroundStyle(Theme.textMuted)

                aiConsentDisclosure
                    .padding(.top, 6)

                MedicalDisclaimerText()
                    .padding(.top, 6)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }

    /// Apple 5.1.1/5.1.2: explicit consent before sharing personal content with a
    /// third-party AI, obtained before the user reaches any prayer or chat.
    private var aiConsentDisclosure: some View {
        VStack(spacing: 4) {
            Text("By continuing, you agree Eden sends what you share to Anthropic (Claude AI), through Eden's secure server, to write your prayers.")
                .font(.caption2)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.accentText)
        }
    }
}
