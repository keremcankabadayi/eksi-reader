import SwiftUI
import SukelaCore

struct TopicListView: View {
    let feed: Feed
    var provider: FeedProviding = EksiFeedProvider.shared

    @State private var topics: [Topic] = []
    @State private var phase: LoadPhase = .idle

    var body: some View {
        List {
            switch phase {
            case .loading where topics.isEmpty:
                LoadingRow()
            case let .failed(failure):
                ErrorView(failure: failure) { await load() }
                    .listRowSeparator(.hidden)
            default:
                ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                    // NavigationLink kendi ok işaretini çiziyor; satırı
                    // görünmez bir link'in üstüne koyup oku gizliyoruz.
                    ZStack {
                        NavigationLink(value: topic) { EmptyView() }
                            .opacity(0)

                        TopicRow(topic: topic, isEven: index % 2 == 0)
                    }
                    .listRowBackground(TopicRow.background(isEven: index % 2 == 0))
                }
            }
        }
        .listStyle(.plain)
        .eksiNavigationBar()
        .navigationTitle(feed.title)
        // Sabit ve ortalı başlık: kaydırınca küçülüp kaybolmuyor.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(feed.title)
                    .font(.headline)
            }
        }
        .navigationDestination(for: Topic.self) { topic in
            TopicDetailView(topic: topic)
        }
        .refreshable { await load() }
        .task {
            guard topics.isEmpty else { return }
            await load()
        }
    }

    private func load() async {
        phase = .loading
        do {
            topics = try await provider.topics(for: feed)
            phase = .loaded
        } catch {
            phase = .failed(FailureInfo(error))
        }
    }
}


#Preview {
    NavigationStack {
        TopicListView(feed: .gundem, provider: MockFeedProvider.shared)
    }
}
