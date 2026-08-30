import Foundation
import SukelaCore

/// Bir sayfanın çekilmiş hâli. Ayrıştırma boş dönerse ne geldiğini
/// gösterebilmek için ham HTML de taşınıyor.
struct FetchedPage {
    let url: URL
    let status: Int
    let html: String
}

/// Ayrıştırma boş döndüğünde ne geldiğini anlatan hata.
/// Ekşi işaretlemeyi değiştirdiğinde "bir şey yok" demek yerine
/// elimizdekini gösteriyoruz.
struct EmptyParseError: LocalizedError {
    let page: FetchedPage
    let what: String

    var errorDescription: String? { "\(what) bulunamadı." }

    /// Hata ekranındaki "detaylar" bölümünde gösterilen teşhis metni.
    var diagnostics: String {
        let title = Self.documentTitle(in: page.html) ?? "-"
        let excerpt = page.html.prefix(1500)
        return """
        URL: \(page.url.absoluteString)
        HTTP: \(page.status)
        Uzunluk: \(page.html.count)
        Sayfa başlığı: \(title)

        --- HTML başı ---
        \(excerpt)
        """
    }

    private static func documentTitle(in html: String) -> String? {
        guard let open = html.range(of: "<title>", options: .caseInsensitive),
              let close = html.range(
                  of: "</title>", options: .caseInsensitive, range: open.upperBound..<html.endIndex
              ) else { return nil }
        return String(html[open.upperBound..<close.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Gerçek veri kaynağı: sayfayı WKWebView üzerinden çekip SukelaCore ile ayrıştırıyor.
struct EksiFeedProvider: FeedProviding {
    static let shared = EksiFeedProvider()

    /// Ekşi bu başlıkla tam sayfa yerine yalnızca ilgili parçayı döndürüyor.
    /// Başlıksız istekte iki panelli tam sayfa geliyor ve içinde entry listesi
    /// de bulunuyor — başlık listesi ayrıştırıcısının işini zorlaştırıyor.
    /// eksilik-os da varsayılan olarak bunu gönderiyor.
    private static let headers = [
        "X-Requested-With": "XMLHttpRequest",
        "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
    ]

    func topics(for feed: Feed) async throws -> [Topic] {
        let started = ContinuousClock.now
        let page = try await fetch(feed.endpoint)

        let topics: [Topic] = try await Stopwatch.measure("ayrıştırma \(feed.rawValue)") {
            switch feed {
            case .gundem:
                return try TopicListParser.parse(html: page.html)
            case .debe:
                // DEBE başlık değil entry döndürüyor, bağlantıları da farklı biçimde.
                return try DebeParser.parse(html: page.html)
            }
        }
        AppLog.info("\(feed.rawValue) uçtan uca: \(started.duration(to: .now).milliseconds)")

        AppLog.info("\(feed.rawValue): \(topics.count) başlık ayrıştırıldı")
        guard !topics.isEmpty else {
            AppLog.warn("\(feed.rawValue): ayrıştırma boş döndü, sayfa başlığı: \(page.html.count) karakter")
            throw EmptyParseError(page: page, what: "Başlık")
        }
        return topics
    }

    func topicPage(link: String, page: Int?) async throws -> TopicPage {
        let started = ContinuousClock.now
        let fetched = try await fetch(.topic(link: link, page: page))
        // Tam sayfa geldiyse üst menüde oturum durumu yazıyor; parça HTML
        // geldiyse ayrıştırıcı "belirsiz" deyip eldeki duruma dokunmuyor.
        await AuthSession.shared.apply(html: fetched.html)

        let parsed = try await Stopwatch.measure("ayrıştırma başlık sayfası") {
            try EntryPageParser.parse(html: fetched.html)
        }
        AppLog.info("başlık sayfası uçtan uca: \(started.duration(to: .now).milliseconds)")

        AppLog.info("\(link): \(parsed.entries.count) entry, sayfa \(parsed.currentPage)/\(parsed.pageCount)")
        // Sayfa verilmiş oyları da taşıyor; ekrandaki geçici üstyazım artık
        // gereksiz.
        await VoteService.shared.adopt(parsed.entries)
        // Favori durumu da sayfada yazıyor; aynı gerekçeyle üstyazım düşüyor.
        await FavoriteService.shared.adopt(parsed.entries)
        guard !parsed.entries.isEmpty else {
            AppLog.warn("\(link): entry bulunamadı")
            throw EmptyParseError(page: fetched, what: "Entry")
        }
        return parsed
    }

    /// Favorileyenler listesi parça HTML olarak geliyor; sayfanın geri
    /// kalanı yok, oturum durumu için bakılacak bir şey de yok.
    func favoriteAuthors(entryId: String) async throws -> [String] {
        let fetched = try await fetch(.favoriteAuthors(entryId: entryId))
        let nicks = try FavoriteListParser.parse(html: fetched.html)
        AppLog.info("entry \(entryId): \(nicks.count) favorileyen")
        return nicks
    }

    private func fetch(_ endpoint: EksiEndpoint) async throws -> FetchedPage {
        guard let url = endpoint.url else { throw FetchError.badResponse }
        return try await WebViewFetcher.shared.fetch(url, headers: Self.headers)
    }
}
