import Foundation
import SwiftSoup

/// Bir başlık sayfasını ve içindeki entry'leri ayrıştırıyor.
///
/// Seçiciler emreisik95/eksilik-os (MIT) projesinden alındı.
public enum EntryPageParser {
    public static func parse(html: String) throws -> TopicPage {
        let document = try SwiftSoup.parse(html)
        // Pretty print entry gövdesine satır sonu sokuyor: "ayakta, <a>bkz</a>"
        // iki satıra bölünüyor. Gövdeyi olduğu gibi almamız gerekiyor.
        document.outputSettings().prettyPrint(pretty: false)

        // Başlık bilgisi h1'in data- özniteliklerinde duruyor.
        let titleElement = try document.select("h1[id^=title]").first()
        let dataTitle = try titleElement?.attr("data-title") ?? ""
        let title = dataTitle.isEmpty ? (try titleElement?.text().trimmed() ?? "") : dataTitle
        let slug = try titleElement?.attr("data-slug") ?? ""
        let topicId = try titleElement?.attr("data-id") ?? ""

        let entries = try parseEntries(in: document)
        let (currentPage, pageCount) = try parsePagination(in: document)

        return TopicPage(
            title: title,
            slug: slug,
            topicId: topicId,
            entries: entries,
            currentPage: currentPage,
            pageCount: pageCount
        )
    }

    /// Dardan genişe; ilk sonuç veren desende duruyoruz.
    private static let entryListSelectors = [
        "ul[id^=entry-item-list] > li",
        "ul.entry-list > li",
        "li[data-author][data-favorite-count]",
    ]

    private static func parseEntries(in document: Document) throws -> [Entry] {
        var items: [Element] = []
        for selector in entryListSelectors {
            items = try document.select(selector).array()
            if !items.isEmpty { break }
        }

        var entries: [Entry] = []

        for item in items {
            let favoriteCount = Int(try item.attr("data-favorite-count")) ?? 0
            let authorNick = try item.attr("data-author")
            let authorId = try item.attr("data-author-id")

            // Gövde ve tarih entry'nin kendi içinde aranıyor; eksilik-os bunları
            // belge genelinde toplayıp indeksle eşliyor, o eşleme bir entry
            // eksik render edildiginde kayiyor.
            let contentHTML = try item.select("div[class^=content]").first()?.html() ?? ""

            let dateElement = try item.select("a[class^=entry-date]").first()
            let date = try dateElement?.text().trimmed() ?? ""
            let href = try dateElement?.attr("href") ?? ""
            let entryId = href.replacingOccurrences(of: "/entry/", with: "")

            let avatarURL = try parseAvatarURL(in: item)

            entries.append(
                Entry(
                    id: entryId.isEmpty ? try item.attr("data-id") : entryId,
                    contentHTML: contentHTML,
                    author: Author(id: authorId, nick: authorNick, avatarURL: avatarURL),
                    date: date,
                    favoriteCount: favoriteCount
                )
            )
        }

        return entries
    }

    private static func parseAvatarURL(in item: Element) throws -> String? {
        guard let img = try item.select("img[src*=ekstat]").first() else { return nil }
        let src = try img.attr("src")
        guard !src.isEmpty else { return nil }
        // Varsayılan avatar taşımaya değmez.
        guard !src.contains("default-profile-picture") else { return nil }
        return src.hasPrefix("//") ? "https:" + src : src
    }

    /// Dardan genişe. AJAX yanıtında pager'ın sınıfı değişebiliyor; sayfalama
    /// kaybolursa "önceki entry'ler" satırı hiç görünmüyor, o yüzden yedeği var.
    private static let pagerSelectors = [
        "div.pager",
        "[data-pagecount]",
    ]

    private static func parsePagination(in document: Document) throws -> (Int, Int) {
        var pager: Element?
        for selector in pagerSelectors {
            pager = try document.select(selector).first()
            if pager != nil { break }
        }
        guard let pager else { return (1, 1) }
        let currentPage = Int(try pager.attr("data-currentpage")) ?? 1
        let pageCount = Int(try pager.attr("data-pagecount")) ?? 1
        return (currentPage, max(pageCount, currentPage))
    }
}
