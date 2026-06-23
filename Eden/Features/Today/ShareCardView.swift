import SwiftUI

/// Branded share card rendered to an image for IG/TikTok.
/// It follows Eden's current light/dark appearance and uses the real current verse.
struct ShareCardView: View {
    let prayerSnippet: String
    let verseText: String
    let verseReference: String

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var bg: Color { isDark ? Color(red: 14 / 255, green: 19 / 255, blue: 32 / 255) : Color(red: 245 / 255, green: 240 / 255, blue: 232 / 255) }
    private var surface: Color { isDark ? Color(red: 26 / 255, green: 34 / 255, blue: 51 / 255) : .white }
    private var primary: Color { isDark ? Color(red: 244 / 255, green: 239 / 255, blue: 230 / 255) : Color(red: 42 / 255, green: 38 / 255, blue: 32 / 255) }
    private var muted: Color { isDark ? Color(red: 138 / 255, green: 147 / 255, blue: 166 / 255) : Color(red: 107 / 255, green: 100 / 255, blue: 87 / 255) }
    private var accent: Color { isDark ? Color(red: 224 / 255, green: 169 / 255, blue: 85 / 255) : Color(red: 176 / 255, green: 125 / 255, blue: 46 / 255) }

    var body: some View {
        ZStack {
            bg
            subtleHills

            VStack(spacing: 42) {
                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "cross")
                        .font(.system(size: 62, weight: .medium))
                        .foregroundStyle(accent)
                    Text("Eden")
                        .font(.system(size: 44, weight: .medium, design: .serif))
                        .foregroundStyle(accent)
                }

                VStack(spacing: 28) {
                    Text("\"\(shareVerseText)\"")
                        .font(.system(size: 58, weight: .semibold, design: .serif))
                        .foregroundStyle(primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(10)
                        .lineLimit(8)
                        .minimumScaleFactor(0.68)

                    if !verseReference.isEmpty {
                        Text(verseReference)
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(accent)
                    }
                }
                .padding(.vertical, 72)
                .padding(.horizontal, 76)
                .background(surface.opacity(isDark ? 0.72 : 0.92), in: RoundedRectangle(cornerRadius: 44))
                .padding(.horizontal, 76)

                if !prayerSnippet.isEmpty {
                    Text(prayerSnippet)
                        .font(.system(size: 34, weight: .medium, design: .serif))
                        .foregroundStyle(muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .lineLimit(4)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 120)
                }

                Spacer()

                VStack(spacing: 10) {
                    Text("Daily prayer for what you're carrying")
                        .font(.system(size: 34, weight: .medium))
                    Text("Get your own prayer in Eden")
                        .font(.system(size: 30))
                        .foregroundStyle(accent)
                }
                .foregroundStyle(accent)
                .multilineTextAlignment(.center)
                .padding(.bottom, 90)
            }
        }
    }

    private var shareVerseText: String {
        let cleanVerse = verseText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanVerse.isEmpty { return cleanVerse }
        return prayerSnippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var subtleHills: some View {
        VStack {
            Spacer()
            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill((isDark ? accent.opacity(0.08) : Color(red: 198 / 255, green: 221 / 255, blue: 195 / 255).opacity(0.5)))
                    .frame(width: 1280, height: 520)
                    .offset(y: 250)
                Ellipse()
                    .fill((isDark ? accent.opacity(0.05) : Color(red: 160 / 255, green: 197 / 255, blue: 160 / 255).opacity(0.42)))
                    .frame(width: 1180, height: 420)
                    .offset(y: 250)
            }
            .frame(height: 430)
        }
        .ignoresSafeArea()
    }
}
