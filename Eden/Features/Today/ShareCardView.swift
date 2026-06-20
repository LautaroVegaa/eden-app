import SwiftUI

/// The branded card rendered to an image for sharing to IG/TikTok — the
/// in-product viral loop. Uses fixed brand colors (never inverts).
struct ShareCardView: View {
    let snippet: String
    let verse: String

    private let bg = Color(red: 14 / 255, green: 19 / 255, blue: 32 / 255)
    private let cream = Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255)
    private let gold = Color(red: 224 / 255, green: 169 / 255, blue: 85 / 255)

    var body: some View {
        ZStack {
            bg
            VStack(spacing: 48) {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundStyle(gold)
                    Text("Eden")
                        .font(.system(size: 44, weight: .medium, design: .serif))
                        .foregroundStyle(gold)
                }
                Text(snippet)
                    .font(.system(size: 58, weight: .semibold, design: .serif))
                    .foregroundStyle(cream)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .padding(.horizontal, 110)
                    .lineLimit(8)
                    .minimumScaleFactor(0.75)
                if !verse.isEmpty {
                    Text(verse)
                        .font(.system(size: 40, design: .serif))
                        .foregroundStyle(gold)
                }
                Spacer()
                VStack(spacing: 10) {
                    Text("Daily prayer for anxious Christians")
                        .font(.system(size: 34, weight: .medium))
                    Text("Get your own prayer in Eden")
                        .font(.system(size: 30))
                        .foregroundStyle(gold)
                }
                    .foregroundStyle(gold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 90)
            }
        }
    }
}
