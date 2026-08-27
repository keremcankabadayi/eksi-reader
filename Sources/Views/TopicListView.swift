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
                ForEach(topics) { topic in
                    NavigationLink(value: topic) {
                        TopicRow(topic: topic)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(feed.title)
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

private struct TopicRow: View {
    let topic: Topic

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(topic.title)
            Spacer(minLength: 12)
            if !topic.entryCount.isEmpty {
                Text(topic.entryCount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

#Preview {
    NavigationStack {
        TopicListView(feed: .gundem, provider: MockFeedProvider.shared)
    }
}
