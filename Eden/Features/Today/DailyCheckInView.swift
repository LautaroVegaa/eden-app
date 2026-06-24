import SwiftUI

/// The daily check-in: a quick "how are you feeling today?" that drives today's
/// prayer. Low friction (one tap + optional note) so the daily habit sticks.
struct DailyCheckInView: View {
    let name: String
    let onSubmit: (_ feeling: String, _ note: String) -> Void

    @AppStorage(AppConfig.aiConsentKey) private var aiConsentGranted = false
    @Environment(\.openURL) private var openURL
    @State private var selected: String?
    @State private var note = ""
    @FocusState private var focused: Bool

    private let feelings = [
        "Anxiety", "Fear about the future", "Loneliness",
        "Doubt", "Relationships", "Something else"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(name.isEmpty ? "How are you feeling today?" : "How are you feeling today, \(name)?")
                .font(.system(.title2, design: .serif).weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text("We'll write today's prayer for exactly this.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                ForEach(feelings, id: \.self) { feeling in
                    Button { selected = feeling } label: {
                        Text(feeling)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 8)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(selected == feeling ? Theme.accentFill : .clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            ZStack(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Anything you want to add? (optional)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
                TextField("", text: $note, axis: .vertical)
                    .lineLimit(1...3)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .focused($focused)
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))

            if !aiConsentGranted {
                aiConsentDisclosure
            }

            Button("Get today's prayer") {
                guard let selected else { return }
                focused = false
                aiConsentGranted = true
                onSubmit(selected, note.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            .buttonStyle(EdenPrimaryButtonStyle())
            .disabled(selected == nil)
            .opacity(selected == nil ? 0.6 : 1)
            .padding(.top, 4)
        }
    }

    /// Apple 5.1.1/5.1.2: explicit consent before sharing personal content with a
    /// third-party AI. Shown until granted (the first prayer is the first send).
    private var aiConsentDisclosure: some View {
        VStack(spacing: 6) {
            (
                Text("By tapping ")
                + Text("Get today's prayer").fontWeight(.semibold)
                + Text(", you agree Eden sends your first name and what you share through its secure server to Anthropic (Claude AI) to write your prayer. If you use Listen, the generated prayer is sent to OpenAI to create temporary audio. Eden does not store this content on its servers.")
            )
            .font(.caption2)
            .foregroundStyle(Theme.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)

            Button("Privacy Policy") { openURL(AppConfig.privacyPolicyURL) }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.accentText)
        }
        .padding(.top, 4)
    }
}
