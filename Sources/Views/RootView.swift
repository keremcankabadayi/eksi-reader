import SwiftUI
import SukelaCore

struct RootView: View {
    /// Widget'tan gelen bağlantı gündem sekmesinde açılıyor.
    @State private var selection: String = Feed.gundem.id
    @State private var gundemPath = NavigationPath()

    var body: some View {
        TabView(selection: $selection) {
            ForEach(Feed.allCases) { feed in
                Group {
                    if feed == .gundem {
                        NavigationStack(path: $gundemPath) {
                            TopicListView(feed: feed)
                        }
                    } else {
                        NavigationStack {
                            TopicListView(feed: feed)
                        }
                    }
                }
                .tabItem {
                    Label(feed.title, systemImage: feed.systemImage)
                }
                .tag(feed.id)
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("ayarlar", systemImage: "gearshape")
            }
            .tag("ayarlar")
        }
        .onOpenURL { url in
            guard case let .topic(link, title)? = DeepLink.parse(url) else { return }
            selection = Feed.gundem.id
            gundemPath.append(
                Topic(id: link, title: title, slug: "", entryCount: "", link: link)
            )
        }
    }
}

#Preview {
    RootView()
}
