import SwiftUI

struct StreakCard: View {
    let currentStreak: Int
    let prayedToday: Bool
    let onPrayed: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill").foregroundStyle(Theme.accentText)
                Text("\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
            }

            if prayedToday {
                Label("Prayed today", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            } else {
                Button("I prayed today", action: onPrayed)
                    .buttonStyle(EdenPrimaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
