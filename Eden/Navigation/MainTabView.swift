import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: MainTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "sun.max.fill")
            }
            .tag(MainTab.today)

            NavigationStack {
                TalkToGodView {
                    selectedTab = .today
                }
            }
            .tabItem {
                Label("Talk", systemImage: "sparkles")
            }
            .tag(MainTab.talk)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle.fill")
            }
            .tag(MainTab.profile)
        }
        .tint(Theme.accentText)
        .onChange(of: selectedTab) { _, _ in
            HapticService.selection()
        }
    }

    private enum MainTab: Hashable {
        case today
        case talk
        case profile
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, DailyPrayer.self], inMemory: true)
}
