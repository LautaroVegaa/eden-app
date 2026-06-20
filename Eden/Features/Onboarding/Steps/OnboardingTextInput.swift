import SwiftUI

struct OnboardingTextInput: View {
    let title: String
    let subtitle: String
    let placeholder: String
    let buttonTitle: String
    let onContinue: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 28) {
            OnboardingHeader(title: title, subtitle: subtitle)
                .padding(.top, 40)

            TextField(placeholder, text: $text)
                .font(.title3)
                .foregroundStyle(Theme.textPrimary)
                .padding(16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
                .focused($focused)

            Spacer()

            Button(buttonTitle) { onContinue(text) }
                .buttonStyle(EdenPrimaryButtonStyle())
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .onAppear { focused = true }
    }
}
