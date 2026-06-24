import SwiftUI

/// Emotional notification priming before the real iOS permission prompt.
struct OnboardingNotifications: View {
    let onDecision: (Bool) -> Void

    private func proceed(_ allow: Bool) {
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

            VStack(spacing: 12) {
                Button("Allow notifications") { proceed(true) }
                    .buttonStyle(EdenPrimaryButtonStyle())
                Button("Maybe later") { proceed(false) }
                    .font(.edenButton)
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.top, 8)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
}
