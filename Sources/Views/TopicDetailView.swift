import SwiftUI
import SukelaCore

struct TopicDetailView: View {
    let topic: Topic
    var provider: FeedProviding = EksiFeedProvider.shared

    @AppStorage("entryFontSize") private var fontSize: Double = 16
    @State private var page: TopicPage?
    @State private var phase: LoadPhase = .idle

    var body: some View {
        ScrollView {
            switch phase {
            case .loading where page == nil:
                ProgressView().padding(.vertical, 48)
            case let .failed(failure):
                ErrorView(failure: failure) { await load() }
                    .padding(.horizontal)
            default:
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(page?.entries ?? []) { entry in
                        EntryRow(entry: entry, fontSize: fontSize)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(page?.title ?? topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task {
            guard page == nil else { return }
            await load()
        }
    }

    private func load() async {
        phase = .loading
        do {
            page = try await provider.topicPage(link: topic.link, page: 1)
            phase = .loaded
        } catch {
            phase = .failed(FailureInfo(error))
        }
    }
}

private struct EntryRow: View {
    let entry: Entry
    let fontSize: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.plainText)
                .font(.system(size: fontSize))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Spacer()
                if entry.favoriteCount > 0 {
                    Label("\(entry.favoriteCount)", systemImage: "heart")
                }
                Text("\(entry.author.nick) · \(entry.date)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Divider()
        }
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(
            topic: Topic(id: "1", title: "test", slug: "t", entryCount: "3", link: "/t--1"),
            provider: MockFeedProvider.shared
        )
    }
}
