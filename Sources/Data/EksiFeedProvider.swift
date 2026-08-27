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
        let page = try await fetch(feed.endpoint)
        let topics: [Topic]
        switch feed {
        case .gundem:
            topics = try TopicListParser.parse(html: page.html)
        case .debe:
            // DEBE başlık değil entry döndürüyor, bağlantıları da farklı biçimde.
            topics = try DebeParser.parse(html: page.html)
        }

        guard !topics.isEmpty else {
            throw EmptyParseError(page: page, what: "Başlık")
        }
        return topics
    }

    func topicPage(link: String, page: Int) async throws -> TopicPage {
        let fetched = try await fetch(.topic(link: link, page: page))
        let parsed = try EntryPageParser.parse(html: fetched.html)

        guard !parsed.entries.isEmpty else {
            throw EmptyParseError(page: fetched, what: "Entry")
        }
        return parsed
    }

    private func fetch(_ endpoint: EksiEndpoint) async throws -> FetchedPage {
        guard let url = endpoint.url else { throw FetchError.badResponse }
        return try await WebViewFetcher.shared.fetch(url, headers: Self.headers)
    }
}
