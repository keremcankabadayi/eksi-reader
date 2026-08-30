import SwiftUI
import SukelaCore

struct TopicListView: View {
    let feed: Feed
    /// Üst bardaki menü düğmesi; sağdaki çekmeceyi RootView açıyor.
    var openMenu: (() -> Void)? = nil
    var provider: FeedProviding = EksiFeedProvider.shared

    /// Okunmuş entry kaydı; debe satırlarında nokta bunun için.
    @EnvironmentObject private var read: ReadTracker

    @State private var topics: [Topic] = []
    @State private var phase: LoadPhase = .idle
    /// Ekranda önbellekten gelen liste dururken ağdan taze liste bekleniyor.
    @State private var refreshing = false
    /// Arama kutusundaki metin. Yazdıkça ekrandaki liste süzülüyor.
    @State private var query = ""
    /// Klavyedeki "ara" tuşuyla açılan arama sayfası. Kutu sonradan
    /// temizlenirse açık sayfa kapanmasın diye ayrıca tutuluyor.
    @State private var searching = false
    @State private var submittedSearch: Topic?

    /// Baştaki ve sondaki boşluk kullanıcının niyeti değil.
    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Ekrandaki liste: arama kutusu doluyken yalnız eşleşen başlıklar.
    /// Süzme yerel, elimizdeki listede; Ekşi'de aramak ayrı bir satır.
    private var visibleTopics: [Topic] {
        guard !trimmedQuery.isEmpty else { return topics }
        return topics.filter { $0.title.localizedCaseInsensitiveContains(trimmedQuery) }
    }

    /// Debe'de okunmamış entry sayısı.
    private var unread: Int {
        read.unreadCount(in: topics)
    }

    /// "ekşi'de ara" satırının gittiği yer: sitenin kendi arama yolu.
    private var searchTopic: Topic? {
        guard let link = EntryLink.lookupLink(for: trimmedQuery) else { return nil }
        return Topic(id: link, title: trimmedQuery, slug: "", entryCount: "", link: link)
    }

    var body: some View {
        List {
            // Listenin ilk satırı: aşağı kaydırınca kayıp gidiyor, en üste
            // dönünce geri geliyor. Uygulama açıldığında liste en üstte
            // olduğu için kutu görünür durumda başlıyor.
            TopicSearchField(query: $query) {
                guard let searchTopic else { return }
                submittedSearch = searchTopic
                searching = true
            }
            .listRowBackground(Palette.base)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 4, trailing: 12))

            if let searchTopic {
                NavigationLink(value: searchTopic) {
                    Label("ekşi'de ara: \(searchTopic.title)", systemImage: "magnifyingglass")
                        .font(.footnote)
                        .foregroundStyle(Palette.link)
                }
                .listRowBackground(Palette.base)
                .listRowSeparator(.hidden)
            }

            switch phase {
            case .loading where topics.isEmpty:
                // Boş ekran + çarkıfelek yerine listenin iskeleti.
                SkeletonList()
            case let .failed(failure) where topics.isEmpty:
                ErrorView(failure: failure) { await load() }
                    .listRowSeparator(.hidden)
            default:
                ForEach(Array(visibleTopics.enumerated()), id: \.element.id) { index, topic in
                    // NavigationLink kendi ok işaretini çiziyor; satırı
                    // görünmez bir link'in üstüne koyup oku gizliyoruz.
                    ZStack {
                        NavigationLink(value: topic) { EmptyView() }
                            .opacity(0)

                        TopicRow(
                            topic: topic,
                            isEven: index % 2 == 0,
                            // Okundu kaydı yalnız debe'de: gündemde nil
                            // geçiyor, satırda okundu izi hiç çıkmıyor.
                            isRead: feed == .debe ? read.isRead(topic) : nil
                        )
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
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    // Debe'de kaç entry kaldı. Slack'in "catch up"ı gibi:
                    // liste bitene kadar sayı düşüyor.
                    if feed == .debe, unread > 0 {
                        Text("\(unread)")
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Palette.link))
                            .accessibilityLabel("\(unread) entry okunmadı")
                    }

                    // Önbellekteki liste dururken tazesi geliyor; sessizce
                    // olmasın. Üst bar dolu renkte, gösterge beyaz.
                    if refreshing && !topics.isEmpty {
                        BrandLoader(width: 16, tint: .white)
                    }

                    if let openMenu {
                        Button(action: openMenu) {
                            Image(systemName: "line.3.horizontal")
                        }
                        .accessibilityLabel("menü")
                    }
                }
            }
        }
        // Kaydırmaya başlayınca klavye kapanıyor; arama kutusu da listeyle
        // birlikte yukarı kayıp gidebilsin diye.
        .scrollDismissesKeyboard(.immediately)
        .navigationDestination(for: Topic.self) { topic in
            // Debe'de her satır tek bir entry; komşuları veriyoruz ki
            // ekranda sağa/sola kaydırarak önceki/sonraki entry'ye geçilsin.
            // Gündemde satır bir başlık, kaydırmanın karşılığı yok.
            TopicDetailView(topic: topic, siblings: feed == .debe ? visibleTopics : [])
        }
        // Klavyedeki "ara" tuşu aynı yere gidiyor; satıra dokunmak şart değil.
        .navigationDestination(isPresented: $searching) {
            if let submittedSearch {
                TopicDetailView(topic: submittedSearch)
            }
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
    .environmentObject(ReadTracker.shared)
}
