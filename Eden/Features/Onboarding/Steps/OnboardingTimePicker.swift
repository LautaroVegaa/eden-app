import SwiftUI

struct OnboardingTimePicker: View {
    let title: String
    let subtitle: String
    let onContinue: (Date) -> Void

    @State private var time = Calendar.current.date(
        from: DateComponents(hour: 22, minute: 0)
    ) ?? Date()

    var body: some View {
        VStack(spacing: 0) {
            OnboardingHeader(title: title, subtitle: subtitle)
                .padding(.top, 40)
                .padding(.horizontal, 24)

            Spacer()

            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()

            Spacer()

            Button("Continue") { onContinue(time) }
                .buttonStyle(EdenPrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}
