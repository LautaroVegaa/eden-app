import SwiftUI

/// The written confession — deepest sunk-cost, and the real input for the
/// first AI prayer (wired in a later block).
struct OnboardingConfession: View {
    let onContinue: (String) -> Void

    @State private var text = ""
    @FocusState private var focused: Bool

    private let placeholder = "e.g. I can't sleep because I'm scared about what comes next..."

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
            }
            .frame(minHeight: 150)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))

            Text("Used only to generate your prayer.")
                .font(.caption)
                .foregroundStyle(Theme.textMuted)

            Spacer()

            Button("Build My Prayer") { onContinue(text) }
                .buttonStyle(EdenPrimaryButtonStyle())
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
    }
}
