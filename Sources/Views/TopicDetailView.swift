import Foundation
import SwiftUI
import SukelaCore

struct TopicDetailView: View {
    let topic: Topic
    var provider: FeedProviding = EksiFeedProvider.shared

    @AppStorage("entryFontSize") private var fontSize: Double = 16
    /// Sayfalar sırayla duruyor; başa eklenen her sayfa daha eski entry'ler.
    @State private var pages: [TopicPage] = []
    @State private var phase: LoadPhase = .idle
    @State private var loadingPrevious = false
    @State private var previousFailure: String?

    private var entries: [Entry] { pages.flatMap(\.entries) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                switch phase {
                case .loading where pages.isEmpty:
                    ProgressView().padding(.vertical, 48)
                case let .failed(failure) where pages.isEmpty:
                    ErrorView(failure: failure) { await load() }
                        .padding(.horizontal)
                default:
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if let preceding = pages.first?.precedingEntryCount, preceding > 0 {
                            PreviousEntriesButton(
                                count: preceding,
                                loading: loadingPrevious,
                                failure: previousFailure
                            ) {
                                await loadPrevious(anchoring: proxy)
                            }
                        }

                        ForEach(entries) { entry in
                            EntryRow(entry: entry, fontSize: fontSize)
                                .id(entry.id)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(pages.first?.title ?? topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task {
            guard pages.isEmpty else { return }
            await load()
        }
    }

    private func load() async {
        phase = .loading
        previousFailure = nil
        do {
            // page: nil — bağlantı nereye işaret ediyorsa oraya. Ekşi daha önce
            // açtığın başlıkta kaldığın sayfayı veriyor, yani başlık ortadan
            // açılabiliyor; öncesi "N entry daha" ile yükleniyor.
            pages = [try await provider.topicPage(link: topic.link, page: nil)]
            phase = .loaded
        } catch {
            pages = []
            phase = .failed(FailureInfo(error))
        }
    }

    private func loadPrevious(anchoring proxy: ScrollViewProxy) async {
        guard !loadingPrevious, let target = pages.first?.previousPage else { return }
        loadingPrevious = true
        previousFailure = nil
        defer { loadingPrevious = false }

        // Yukarı ekleme yaptığımızda liste zıplıyor; şu an en üstteki entry'yi
        // işaretleyip ekledikten sonra oraya geri sabitliyoruz.
        let anchorID = entries.first?.id
        do {
            let previous = try await provider.topicPage(link: topic.link, page: target)
            pages.insert(previous, at: 0)
            if let anchorID {
                DispatchQueue.main.async { proxy.scrollTo(anchorID, anchor: .top) }
            }
        } catch {
            previousFailure = error.localizedDescription
        }
    }
}

/// Başlığın üstünde kalan eski entry'leri yükleyen satır.
private struct PreviousEntriesButton: View {
    let count: Int
    let loading: Bool
    let failure: String?
    let load: () async -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button {
                Task { await load() }
            } label: {
                HStack(spacing: 6) {
                    if loading {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.up")
                    }
                    Text("\(count) entry daha")
                }
                .font(.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.bordered)
            .disabled(loading)

            if let failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
