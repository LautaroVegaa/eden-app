import SwiftUI

/// Serif for the sacred (verses, prayers, titles), sans for UI.
extension Font {
    static let edenTitle = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let edenHeading = Font.system(.title2, design: .serif).weight(.medium)
    static let edenBody = Font.system(.body)
    static let edenButton = Font.system(.headline)
}

extension View {
    func edenTitleStyle() -> some View {
        font(.edenTitle)
            .foregroundStyle(Theme.textPrimary)
            .multilineTextAlignment(.center)
    }

    func edenBodyStyle() -> some View {
        font(.edenBody)
            .foregroundStyle(Theme.textMuted)
            .multilineTextAlignment(.center)
    }
}
