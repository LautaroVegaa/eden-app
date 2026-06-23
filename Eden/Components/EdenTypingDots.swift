import SwiftUI

struct EdenTypingDots: View {
    @State private var activeDot = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Theme.accentFill)
                    .frame(width: 6, height: 6)
                    .opacity(activeDot == index ? 1 : 0.35)
                    .offset(y: activeDot == index ? -3 : 0)
                    .animation(.easeInOut(duration: 0.22), value: activeDot)
            }
        }
        .frame(width: 34, height: 14)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(280))
                activeDot = (activeDot + 1) % 3
            }
        }
    }
}
