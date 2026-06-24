import SwiftUI

/// The written confession — deepest sunk-cost, and the real input for the
/// first AI prayer (wired in a later block).
struct OnboardingConfession: View {
    let onContinue: (String) -> Void

    @Environment(\.openURL) private var openURL
    @State private var text = ""
    @State private var showValidation = false
    @FocusState private var focused: Bool

    private let placeholder = "e.g. I can't sleep because I'm scared about what comes next..."
    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        trimmedText.count >= 8
    }

    var body: some View {
        VStack(spacing: 24) {
            OnboardingHeader(
                title: "God already knows. But writing it down changes something.",
                subtitle: "What you type helps generate your first prayer. It is not public."
            )
            .padding(.top, 40)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                }
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .focused($focused)
                    .onChange(of: text) { _, _ in
                        if showValidation, isValid { showValidation = false }
                    }
            }
            .frame(minHeight: 150)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(showValidation && !isValid ? Theme.accentFill : .clear, lineWidth: 1)
            )

            Text(showValidation && !isValid ? "Write one honest sentence to continue." : "Used only to generate your prayer.")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)

            Spacer()

            aiConsentDisclosure

            Button("Build My Prayer") {
                guard isValid else {
                    showValidation = true
                    return
                }
                onContinue(trimmedText)
            }
            .buttonStyle(EdenPrimaryButtonStyle())
            .opacity(isValid ? 1 : 0.6)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }

    /// Apple 5.1.1/5.1.2: explicit, specific consent before sharing personal
    /// content with a third-party AI. Names the processor and links the policy.
    private var aiConsentDisclosure: some View {
        VStack(spacing: 6) {
            (
                Text("By tapping ")
                + Text("Build My Prayer").fontWeight(.semibold)
                + Text(", you agree Eden sends your first name and what you share through its secure server to Anthropic (Claude AI) to write your prayer. If you use Listen, the generated prayer is sent to OpenAI to create temporary audio. Eden does not store this content on its servers.")
            )
            .font(.caption2)
            .foregroundStyle(Theme.textMuted)
            .multilineTextAlignment(.center)

            Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.accentText)
        }
        .padding(.horizontal, 4)
    }
}
