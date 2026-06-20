import SwiftUI
import UIKit

struct PrayerCard: View {
    let body_: String
    let isSpeaking: Bool
    let onToggleListen: () -> Void
    let shareImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("YOUR PRAYER", systemImage: "hands.sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)

            Text(body_)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button(action: onToggleListen) {
                    Label(isSpeaking ? "Stop" : "Listen",
                          systemImage: isSpeaking ? "stop.fill" : "headphones")
                }
                .buttonStyle(.bordered)
                .tint(Theme.accent)

                if let shareImage {
                    ShareLink(
                        item: Image(uiImage: shareImage),
                        preview: SharePreview("Eden", image: Image(uiImage: shareImage))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.accent)
                }
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
