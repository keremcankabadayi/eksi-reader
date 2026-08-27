import SwiftUI
import SukelaCore

struct TopicListView: View {
    let feed: Feed
    var provider: FeedProviding = EksiFeedProvider.shared

    @State private var topics: [Topic] = []
    @State private var phase: LoadPhase = .idle
    /// Ekranda önbellekten gelen liste dururken ağdan taze liste bekleniyor.
    @State private var refreshing = false

    var body: some View {
        List {
            switch phase {
            case .loading where topics.isEmpty:
                // Boş ekran + çarkıfelek yerine listenin iskeleti.
                SkeletonList()
            case let .failed(failure) where topics.isEmpty:
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
        // Liste kendi zeminini çiziyor; palet zemini görünsün diye kapatıp
        // altına kendi rengimizi koyuyoruz.
        .scrollContentBackground(.hidden)
        .background(Palette.base)
        .eksiNavigationBar()
        .navigationTitle(feed.title)
        // Sabit ve ortalı başlık: kaydırınca küçülüp kaybolmuyor.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(feed.title)
                    .font(.headline)
            }
            // Önbellekteki liste dururken tazesi geliyor; sessizce olmasın.
            ToolbarItem(placement: .navigationBarTrailing) {
                if refreshing && !topics.isEmpty {
                    ProgressView().tint(.white)
                }
            }
        }
        .navigationDestination(for: Topic.self) { topic in
            TopicDetailView(topic: topic)
        }
        .refreshable { await load() }
        .task {
            guard topics.isEmpty else { return }
            // Önce diskteki son liste: Cloudflare doğrulaması ve istek
            // beklenmeden ekranda gerçek başlıklar oluyor.
            if let cached = FeedCache.read(feed) {
                topics = cached
                phase = .loaded
            }
            await load()
        }
    }

    private func load() async {
        if topics.isEmpty { phase = .loading }
        refreshing = true
        defer { refreshing = false }

        do {
            let fresh = try await provider.topics(for: feed)
            topics = fresh
            phase = .loaded
            FeedCache.write(fresh, for: feed)
            // Widget veriyi kendi çekemiyor; son gündemi ona bırakıyoruz.
            if feed == .gundem {
                WidgetBridge.publish(fresh)
            }
        } catch {
            // Önbellekten gelen liste ekrandaysa hatayı ekrana basmıyoruz;
            // eldeki bayat liste boş ekrandan iyi, günlüğe yazıp geçiyoruz.
            guard topics.isEmpty else {
                AppLog.warn("\(feed.rawValue): tazeleme düştü, önbellek duruyor")
                return
            }
            phase = .failed(FailureInfo(error))
        }
    }
}


#Preview {
    NavigationStack {
        TopicListView(feed: .gundem, provider: MockFeedProvider.shared)
    }
}
