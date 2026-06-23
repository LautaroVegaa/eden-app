import SwiftUI

/// Branded cold-start splash: the Eden mark with the name below, easing in.
/// Doubles as the quiet loader while subscription state resolves.
struct SplashView: View {
    @State private var appear = false

    var body: some View {
        ScreenContainer {
            VStack(spacing: 18) {
                EdenLoadingMark(size: 66)
                    .scaleEffect(appear ? 1 : 0.82)
                    .opacity(appear ? 1 : 0)

                Text("Eden")
                    .font(.system(.largeTitle, design: .serif).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) { appear = true }
        }
    }
}

#Preview {
    SplashView()
}
