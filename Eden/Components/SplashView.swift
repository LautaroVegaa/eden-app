import SwiftUI

/// Cold-start splash: the static Eden mark with the name below. No animation.
struct SplashView: View {
    var body: some View {
        ScreenContainer {
            VStack(spacing: 18) {
                EdenMark(size: 78)
                Text("Eden")
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// The static Eden app mark: a cross inside an open ring (gap at the bottom).
private struct EdenMark: View {
    var size: CGFloat = 78

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(
                    Theme.accentFill,
                    style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round)
                )
                .rotationEffect(.degrees(90)) // move the gap to the bottom
                .frame(width: size, height: size)

            RoundedRectangle(cornerRadius: size * 0.035)
                .fill(Theme.accentFill)
                .frame(width: size * 0.12, height: size * 0.52)

            RoundedRectangle(cornerRadius: size * 0.035)
                .fill(Theme.accentFill)
                .frame(width: size * 0.36, height: size * 0.105)
                .offset(y: -size * 0.08)
        }
    }
}

#Preview {
    SplashView()
}
