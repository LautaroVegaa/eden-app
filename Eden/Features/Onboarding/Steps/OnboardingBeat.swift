import SwiftUI

/// Emotional beat — no input, just connection. Breaks form fatigue.
struct OnboardingBeat: View {
    let title: String
    let message: String
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(title)
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.body)
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
            Spacer()
            Button("Continue", action: onContinue)
                .buttonStyle(EdenPrimaryButtonStyle())
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}
