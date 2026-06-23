import SwiftUI

struct OnboardingTextInput: View {
    let title: String
    let subtitle: String
    let placeholder: String
    let buttonTitle: String
    let onContinue: (String) -> Void

    @State private var text = ""
    @State private var showValidation = false
    @FocusState private var focused: Bool

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        trimmedText.count >= 2
    }

    var body: some View {
        VStack(spacing: 28) {
            OnboardingHeader(title: title, subtitle: subtitle)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 8) {
                TextField(placeholder, text: $text)
                    .font(.title3)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(16)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(showValidation && !isValid ? Theme.accentFill : .clear, lineWidth: 1)
                    )
                    .focused($focused)
                    .onChange(of: text) { _, _ in
                        if showValidation, isValid { showValidation = false }
                    }

                if showValidation && !isValid {
                    Text("Enter your name to continue.")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
            }

            Spacer()

            Button(buttonTitle) {
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
        .onAppear { focused = true }
    }
}
