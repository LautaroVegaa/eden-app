import SwiftUI
import SwiftData

/// Edit profile sheet: name, default struggle, what they're praying for, and the
/// daily reminder time (reschedules the local notification on save).
struct EditProfileView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String
    @State private var struggle: String
    @State private var desire: String
    @State private var time: Date

    private let struggleOptions = ["Anxiety", "Fear about the future", "Loneliness", "Doubt", "Relationships"]
    private let desireOptions = ["Peace", "Confidence", "Faith", "Direction"]

    init(profile: UserProfile) {
        self.profile = profile
        _name = State(initialValue: profile.name)
        _struggle = State(initialValue: profile.struggle ?? "Anxiety")
        _desire = State(initialValue: profile.desire ?? "Peace")
        _time = State(initialValue: profile.mindRaceTime ?? Self.defaultTime)
    }

    private static var defaultTime: Date {
        Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("You") {
                    TextField("Name", text: $name)
                    Picker("Main weight", selection: $struggle) {
                        ForEach(options(struggleOptions, including: struggle), id: \.self) { Text($0) }
                    }
                    Picker("Praying for", selection: $desire) {
                        ForEach(options(desireOptions, including: desire), id: \.self) { Text($0) }
                    }
                }
                Section("Daily prayer reminder") {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func options(_ base: [String], including current: String) -> [String] {
        base.contains(current) ? base : [current] + base
    }

    private func save() {
        profile.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.struggle = struggle
        profile.desire = desire
        profile.mindRaceTime = time
        try? modelContext.save()
        // Request authorization too, in case notifications were skipped at
        // onboarding — otherwise setting a time here would silently never fire.
        Task { _ = await PrayerNotificationService.shared.requestAndScheduleDailyPrayer(at: time) }
        dismiss()
    }
}
