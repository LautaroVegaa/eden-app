import SwiftUI

struct VerseCard: View {
    let reference: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("YOUR VERSE", systemImage: "book.closed")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text(reference)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
