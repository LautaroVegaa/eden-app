import SwiftUI

struct EdenLoadingMark: View {
    var size: CGFloat = 56

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(
                    Theme.accentFill.opacity(isPulsing ? 0.88 : 0.58),
                    style: StrokeStyle(lineWidth: size * 0.075, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isPulsing ? 6 : -6))

            RoundedRectangle(cornerRadius: size * 0.035)
                .fill(Theme.accentFill)
                .frame(width: size * 0.12, height: size * 0.52)

            RoundedRectangle(cornerRadius: size * 0.035)
                .fill(Theme.accentFill)
                .frame(width: size * 0.36, height: size * 0.105)
                .offset(y: -size * 0.08)
        }
        .scaleEffect(isPulsing ? 1.04 : 0.98)
        .animation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear { isPulsing = true }
    }
}
