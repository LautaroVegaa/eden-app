import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }

            NavigationStack {
                TalkToGodView()
            }
            .tabItem {
                Label("Talk", systemImage: "sparkles")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
