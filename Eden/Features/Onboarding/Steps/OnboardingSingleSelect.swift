import SwiftUI

/// Single-choice step that auto-advances shortly after a tap.
struct OnboardingSingleSelect: View {
    let title: String
    let subtitle: String
    let options: [String]
    let onSelect: (String) -> Void

    @State private var selected: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                OnboardingHeader(title: title, subtitle: subtitle)
                    .padding(.top, 40)
                    .padding(.horizontal, 24)

                VStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        OptionCard(text: option, isSelected: selected == option) {
                            guard selected == nil else { return }
                            selected = option
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                onSelect(option)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
        }
    }
}
