import Foundation
import SwiftUI
import SukelaCore

struct TopicDetailView: View {
    /// Ekranda duran başlık. Debe'de yatay kaydırma bunu komşusuyla
    /// değiştiriyor, o yüzden `let` değil.
    @State private var topic: Topic
    /// Kaydırmayla gezilebilen komşular (debe listesi). Boşsa kaydırma yok.
    private let siblings: [Topic]
    private let provider: FeedProviding

    init(
        topic: Topic,
        siblings: [Topic] = [],
        provider: FeedProviding = EksiFeedProvider.shared
    ) {
        _topic = State(initialValue: topic)
        self.siblings = siblings
        self.provider = provider
    }

    @AppStorage("entryFontSize") private var fontSize: Double = 16
    /// Sayfalar sırayla duruyor; başa eklenen her sayfa daha eski entry'ler.
    @State private var pages: [TopicPage] = []
    @State private var phase: LoadPhase = .idle
    @State private var loadingPrevious = false
    @State private var navigating = false
    @State private var previousFailure: String?
    @State private var pagingFailure: String?

    /// Sayfa değiştirince listenin başına dönmek için.
    private static let topAnchor = "top"
    /// Gövdedeki bir bkz bağlantısına tıklanınca açılan başlık.
    @State private var linkedTopic: Topic?
    /// Harici bağlantı: üstte açılan uygulama içi web kartı.
    @State private var popup: PopupLink?
    /// Favorileyenler kartı açık olan entry.
    @State private var favoritesOf: Entry?

    /// Çizime hazır satırlar. Gövde ayrıştırması burada bir kez yapılıyor;
    /// satır çizilirken yapılırsa liste yukarı kaydırırken takılıyor.
    @State private var rows: [RenderedEntry] = []

    /// Oy hatası burada gösteriliyor: satırın kendi içinde yer yok, düğme
    /// zaten eski hâline dönüyor.
    @EnvironmentObject private var votes: VoteService

    /// Okundu kaydı: açılan debe entry'si işaretleniyor, kaydırma destesi
    /// de sıradakinin okunup okunmadığını buradan öğreniyor.
    @EnvironmentObject private var read: ReadTracker

    /// Sayfalama gerektiren başlıkta son yüklenen sayfa; tek sayfalıkta nil.
    private var pager: TopicPage? {
        guard let last = pages.last, last.pageCount > 1 else { return nil }
        return last
    }

    /// Ekrandaki entry'nin komşu listesindeki yeri; listede yoksa nil.
    private var siblingIndex: Int? {
        siblings.firstIndex { $0.id == topic.id }
    }

    private var previousSibling: Topic? {
        guard let index = siblingIndex, index > 0 else { return nil }
        return siblings[index - 1]
    }

    private var nextSibling: Topic? {
        guard let index = siblingIndex, index + 1 < siblings.count else { return nil }
        return siblings[index + 1]
    }

    /// Sayfalama barı yoksa ve komşular varsa alta debe gezinme barı geliyor.
    private var showsSiblingBar: Bool {
        pager == nil && siblingIndex != nil && siblings.count > 1
    }

    var body: some View {
        ScrollViewReader { proxy in
            // LazyVStack değil List: LazyVStack yukarı kaydırırken görünmeyen
            // satırları atıp geri gelince yeniden ölçüyor, uzun entry'lerde
            // takılma buradan geliyordu. List hücreleri geri dönüştürüyor ve
            // ölçtüğü yüksekliği saklıyor.
            List {
                switch phase {
                case .loading where rows.isEmpty:
                    // Gösterge listenin ilk satırında değil, ekranın
                    // ortasında duruyor (aşağıdaki overlay).
                    EmptyView()
                case let .failed(failure) where rows.isEmpty:
                    ErrorView(failure: failure) { await load() }
                        .listRowSeparator(.hidden)
                default:
                    // Çapa için ayrı bir satır koymuyoruz: List sıfır
                    // yükseklikli satıra da minimum yükseklik verip üstte
                    // boşluk bırakıyor. Listenin ilk satırı neyse o çapa.
                    if let more = pages.first?.previousMore {
                        // Metin ve bağlantı Ekşi'den geliyor; sayıyı biz
                        // hesaplamıyoruz, sayfa başına entry sabit değil.
                        PreviousEntriesButton(
                            label: more.label,
                            loading: loadingPrevious,
                            failure: previousFailure
                        ) {
                            await loadPrevious(more, anchoring: proxy)
                        }
                        .id(Self.topAnchor)
                        .listRowSeparator(.hidden)
                    }

                    // Entry kutuları da başlık listesi gibi zebra: uzun
                    // entry'lerde nerede bitip nerede başladığı ayrışıyor.
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        EntryRow(
                            rendered: row,
                            fontSize: fontSize,
                            openInApp: open(link:title:),
                            openPopup: { popup = $0 },
                            showFavorites: { favoritesOf = row.entry }
                        )
                        .id(row.id)
                        .listRowBackground(Palette.row(isEven: index % 2 == 0))
                        // Sınırı zebra çiziyor; ayraç çizgisi fazlalık.
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            // Liste kendi zeminini çiziyor; palet zemini görünsün diye kapatıp
            // altına kendi rengimizi koyuyoruz.
            .scrollContentBackground(.hidden)
            .background(Palette.base)
            // Debe'de yatay kaydırma komşu entry'ye geçiriyor; hareketin
            // kendisi 3D: sayfa dönerek çıkıyor, gelecek entry kenardan
            // görünüyor.
            .siblingSwipe(
                enabled: showsSiblingBar,
                previous: previousSibling,
                next: nextSibling,
                position: siblingIndex.map { $0 + 1 },
                total: siblings.count,
                isRead: read.isRead(_:),
                onSwitch: show(_:)
            )
            .overlay {
                if phase == .loading, rows.isEmpty {
                    BrandLoadingView()
                }
            }
            // Sayfalama barı sekme çubuğunun yerini alıyor: başlık açıkken
            // gündem/debe/ayarlar gizleniyor, aynı yerde sayfalama duruyor.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let pager {
                    PagerBar(
                        current: pager.currentPage,
                        total: pager.pageCount,
                        loading: navigating,
                        failure: pagingFailure
                    ) { page in
                        await go(to: page, anchoring: proxy)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                    // Zemin ana ekran çubuğunun altına kadar insin.
                    .background(.bar, ignoresSafeAreaEdges: .bottom)
                } else if showsSiblingBar, let index = siblingIndex {
                    // Kaydırmanın düğmeli karşılığı: hem keşfedilir oluyor
                    // hem de kaçıncı entry'de olduğun görünüyor.
                    SiblingBar(
                        current: index + 1,
                        total: siblings.count,
                        previous: previousSibling,
                        next: nextSibling,
                        go: show(_:)
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 2)
                    .background(.bar, ignoresSafeAreaEdges: .bottom)
                }
            }
        }
        .toolbar(pager == nil && !showsSiblingBar ? .visible : .hidden, for: .tabBar)
        .navigationTitle(pages.first?.title ?? topic.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Varsayılan inline başlık tek satır ve uzun başlığı "..." ile
            // kesiyor. Ekşi başlıkları uzun; iki satıra izin veriyoruz.
            // .headline iki satırda üst bara sığmıyor, bir punto küçüğü sığıyor.
            ToolbarItem(placement: .principal) {
                // Sarmayı kendimiz yapıyoruz: SwiftUI dar barda metni
                // küçültüp tek satıra sıkıştırmayı tercih ediyor.
                Text(TitleLayout.twoLines(pages.first?.title ?? topic.title))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        // Geri düğmesinde yalnızca ok kalsın, önceki ekranın adı yazılmasın.
        .toolbarRole(.editor)
        .eksiNavigationBar()
        .refreshable { await load() }
        // Liste ekranındaki `navigationDestination(for: Topic.self)` ile
        // çakışmasın diye bağlantılar isPresented ile açılıyor.
        .navigationDestination(
            isPresented: Binding(
                get: { linkedTopic != nil },
                set: { if !$0 { linkedTopic = nil } }
            )
        ) {
            if let linkedTopic {
                // AnyView şart: ekran kendini açıyor, tip silinmezse `some View`
                // kendi kendine referans veriyor ve derlenmiyor.
                AnyView(TopicDetailView(topic: linkedTopic, provider: provider))
            }
        }
        // Harici bağlantılar Safari'ye gitmiyor, buradaki kartta açılıyor.
        .sheet(item: $popup) { link in
            WebPopupView(link: link)
        }
        .sheet(item: $favoritesOf) { entry in
            FavoriteListView(entry: entry, provider: provider)
        }
        .alert(
            "oy verilemedi",
            isPresented: Binding(
                get: { votes.failure != nil },
                set: { if !$0 { votes.failure = nil } }
            ),
            presenting: votes.failure
        ) { _ in
            Button("tamam", role: .cancel) {}
        } message: { detail in
            Text(detail)
        }
        // id: topic.id — komşuya geçince yeniden koşuyor.
        .task(id: topic.id) {
            // Ekrana gelen entry okundu sayılıyor: debe listesinde noktası
            // sönüyor, üstteki sayaç düşüyor.
            if !siblings.isEmpty { read.markRead(topic) }
            guard pages.isEmpty else { return }
            await load()
        }
    }

    /// Ekranı komşu entry'ye çeviriyor; yükleme `task(id:)` ile başlıyor.
    private func show(_ next: Topic) {
        guard next.id != topic.id else { return }
        pages = []
        rows = []
        phase = .loading
        previousFailure = nil
        pagingFailure = nil
        topic = next
    }

    private static func render(_ pages: [TopicPage]) -> [RenderedEntry] {
        pages.flatMap(\.entries).map(RenderedEntry.init)
    }

    /// bkz bağlantısı: aynı yığında yeni bir başlık ekranı açıyor.
    private func open(link: String, title: String) {
        linkedTopic = Topic(id: link, title: title, slug: "", entryCount: "", link: link)
    }

    private func load() async {
        phase = .loading
        previousFailure = nil
        pagingFailure = nil
        do {
            // page: nil — bağlantı nereye işaret ediyorsa oraya. Ekşi daha önce
            // açtığın başlıkta kaldığın sayfayı veriyor, yani başlık ortadan
            // açılabiliyor; öncesi "N entry daha" ile yükleniyor.
            pages = [try await provider.topicPage(link: topic.link, page: nil)]
            rows = Self.render(pages)
            phase = .loaded
        } catch {
            pages = []
            rows = []
            phase = .failed(FailureInfo(error))
        }
    }

    /// Sayfalama okları: yığını atıp istenen sayfayı gösteriyor.
    private func go(to page: Int, anchoring proxy: ScrollViewProxy) async {
        guard !navigating, page != pages.last?.currentPage else { return }
        navigating = true
        pagingFailure = nil
        defer { navigating = false }

        do {
            pages = [try await provider.topicPage(link: topic.link, page: page)]
            rows = Self.render(pages)
            // "N entry daha" satırı varsa çapa odur, yoksa ilk entry.
            let target: AnyHashable? = pages.first?.previousMore != nil
                ? Self.topAnchor
                : rows.first?.id
            if let target { proxy.scrollTo(target, anchor: .top) }
        } catch {
            // Ekrandaki entry'ler duruyor; hatayı sayfalama barında söylüyoruz.
            pagingFailure = error.localizedDescription
        }
    }

    /// Ekşi'nin verdiği "N entry daha" bağlantısını yükleyip başa ekliyor.
    /// Bağlantı focusto taşıyor, sayfa numarası vermiyoruz ki korunsun.
    private func loadPrevious(_ more: MoreLink, anchoring proxy: ScrollViewProxy) async {
        guard !loadingPrevious else { return }
        loadingPrevious = true
        previousFailure = nil
        defer { loadingPrevious = false }

        // Yukarı ekleme yaptığımızda liste zıplıyor; şu an en üstteki entry'yi
        // işaretleyip ekledikten sonra oraya geri sabitliyoruz.
        let anchorID = rows.first?.id
        do {
            let previous = try await provider.topicPage(link: more.link, page: nil)
            pages.insert(previous, at: 0)
            rows.insert(contentsOf: previous.entries.map(RenderedEntry.init), at: 0)
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
    let label: String
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
                        BrandLoader(width: 14)
                    } else {
                        Image(systemName: "chevron.up")
                    }
                    Text(label)
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

/// Debe gezinme barı: <  3/50  >. Kaydırmanın düğmeli karşılığı.
private struct SiblingBar: View {
    let current: Int
    let total: Int
    let previous: Topic?
    let next: Topic?
    let go: (Topic) -> Void

    var body: some View {
        HStack(spacing: 18) {
            step("chevron.backward", to: previous)

            Text("\(current)/\(total)")
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(Palette.sage)
                .frame(minWidth: 44)

            step("chevron.forward", to: next)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private func step(_ symbol: String, to topic: Topic?) -> some View {
        Button {
            if let topic { go(topic) }
        } label: {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .frame(width: 30, height: 24)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Palette.sage.opacity(topic == nil ? 0.3 : 1))
        .disabled(topic == nil)
    }
}

/// Sayfalama: |<  <  1/3  >  >|
private struct PagerBar: View {
    let current: Int
    let total: Int
    let loading: Bool
    let failure: String?
    let go: (Int) async -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 18) {
                step("chevron.backward.to.line", to: 1, enabled: current > 1)
                step("chevron.backward", to: current - 1, enabled: current > 1)

                if loading {
                    BrandLoader(width: 16, tint: Palette.sage)
                        .frame(minWidth: 44)
                } else {
                    Text("\(current)/\(total)")
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(Palette.sage)
                        .frame(minWidth: 44)
                }

                step("chevron.forward", to: current + 1, enabled: current < total)
                step("chevron.forward.to.line", to: total, enabled: current < total)
            }
            .frame(maxWidth: .infinity)

            if let failure {
                Text(failure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 2)
    }

    private func step(_ symbol: String, to page: Int, enabled: Bool) -> some View {
        Button {
            Task { await go(page) }
        } label: {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .frame(width: 30, height: 24)
        }
        // Çerçeveli düğme barı kalınlaştırıyordu; düz ikon yeterli.
        .buttonStyle(.plain)
        .foregroundStyle(Palette.sage.opacity(enabled && !loading ? 1 : 0.3))
        .disabled(!enabled || loading)
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(
            topic: Topic(id: "1", title: "test", slug: "t", entryCount: "3", link: "/t--1"),
            provider: MockFeedProvider.shared
        )
    }
    .environmentObject(AuthSession.shared)
    .environmentObject(VoteService.shared)
    .environmentObject(ReadTracker.shared)
}
