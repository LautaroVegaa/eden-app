import SwiftUI

/// Emotional notification priming before the real iOS permission prompt.
struct OnboardingNotifications: View {
    let onDecision: (Bool) -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
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
                Button("Allow") { onDecision(true) }
                    .buttonStyle(EdenPrimaryButtonStyle())
                Button("Maybe later") { onDecision(false) }
                    .font(.edenButton)
                    .foregroundStyle(Theme.textMuted)

                MedicalDisclaimerText()
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}
