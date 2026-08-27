import SwiftUI
import SukelaCore

struct RootView: View {
    /// Widget'tan gelen bağlantı gündem sekmesinde açılıyor.
    @State private var selection: String = Feed.gundem.id
    @State private var gundemPath = NavigationPath()
    /// Sağdaki menü.
    @State private var menuOpen = false

    var body: some View {
        DrawerContainer(isOpen: $menuOpen) {
            TabView(selection: $selection) {
                ForEach(Feed.allCases) { feed in
                    Group {
                        if feed == .gundem {
                            NavigationStack(path: $gundemPath) {
                                list(feed)
                            }
                        } else {
                            NavigationStack {
                                list(feed)
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
        }
        .onOpenURL { url in
            guard case let .topic(link, title)? = DeepLink.parse(url) else { return }
            menuOpen = false
            selection = Feed.gundem.id
            gundemPath.append(
                Topic(id: link, title: title, slug: "", entryCount: "", link: link)
            )
        }
    }

    private func list(_ feed: Feed) -> some View {
        TopicListView(feed: feed, openMenu: {
            withAnimation(.easeOut(duration: 0.25)) { menuOpen = true }
        })
    }
}

#Preview {
    RootView()
        .environmentObject(AuthSession.shared)
}
