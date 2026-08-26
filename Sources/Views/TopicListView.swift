import SwiftUI

struct TopicListView: View {
    let feed: Feed
    private let provider: FeedProviding = MockFeedProvider.shared

    var body: some View {
        List(provider.topics(for: feed)) { topic in
            NavigationLink(value: topic) {
                HStack(alignment: .firstTextBaseline) {
                    Text(topic.title)
                    Spacer(minLength: 12)
                    Text("\(topic.entryCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(feed.title)
        .navigationDestination(for: Topic.self) { topic in
            TopicDetailView(topic: topic)
        }
    }
}

#Preview {
    NavigationStack {
        TopicListView(feed: .gundem)
    }
}
