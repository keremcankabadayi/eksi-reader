import SwiftUI

struct TopicDetailView: View {
    let topic: Topic
    @AppStorage("entryFontSize") private var fontSize: Double = 16

    private let provider: FeedProviding = MockFeedProvider.shared

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                ForEach(provider.entries(for: topic)) { entry in
                    EntryRow(entry: entry, fontSize: fontSize)
                }
            }
            .padding()
        }
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EntryRow: View {
    let entry: Entry
    let fontSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.body)
                .font(.system(size: fontSize))
                .textSelection(.enabled)

            HStack(spacing: 8) {
                Spacer()
                if entry.favCount > 0 {
                    Label("\(entry.favCount)", systemImage: "heart")
                        .labelStyle(.titleAndIcon)
                }
                Text("\(entry.author) · \(entry.date)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()
        }
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(topic: Topic(id: 1, title: "test başlığı", entryCount: 3))
    }
}
