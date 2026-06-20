import SwiftUI

struct MedicalDisclaimerText: View {
    var body: some View {
        Text("Eden offers spiritual support, not medical advice, therapy, or emergency care. If you may harm yourself or need urgent help, contact local emergency services.")
            .font(.caption2)
            .foregroundStyle(Theme.textMuted)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
    }
}
