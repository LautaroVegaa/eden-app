import SwiftUI

/// Reusable scaffold: brand background edge-to-edge with content on top.
struct ScreenContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            content
        }
    }
}
