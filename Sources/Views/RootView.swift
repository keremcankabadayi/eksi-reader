import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ForEach(Feed.allCases) { feed in
                NavigationStack {
                    TopicListView(feed: feed)
                }
                .tabItem {
                    Label(feed.title, systemImage: feed.systemImage)
                }
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("ayarlar", systemImage: "gearshape")
            }
        }
    }
}

#Preview {
    RootView()
}
