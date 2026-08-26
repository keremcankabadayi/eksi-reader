import Foundation
import SukelaCore

/// Gerçek veri kaynağı: sayfayı WKWebView üzerinden çekip SukelaCore ile ayrıştırıyor.
struct EksiFeedProvider: FeedProviding {
    static let shared = EksiFeedProvider()

    func topics(for feed: Feed) async throws -> [Topic] {
        let html = try await fetch(feed.endpoint)
        switch feed {
        case .gundem:
            return try TopicListParser.parse(html: html)
        case .debe:
            // DEBE başlık değil entry döndürüyor, bağlantıları da farklı biçimde.
            return try DebeParser.parse(html: html)
        }
    }

    func topicPage(link: String, page: Int) async throws -> TopicPage {
        let html = try await fetch(.topic(link: link, page: page))
        return try EntryPageParser.parse(html: html)
    }

    private func fetch(_ endpoint: EksiEndpoint) async throws -> String {
        guard let url = endpoint.url else { throw FetchError.badResponse }
        return try await WebViewFetcher.shared.fetch(url)
    }
}
