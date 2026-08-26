import Foundation
import SwiftSoup

/// DEBE (dünün en beğenilen entry'leri) sayfasını ayrıştırıyor.
///
/// DEBE gündemden farklı çalışıyor: başlık değil, tek tek entry döndürüyor.
/// Bağlantılar "/entry/12345?debe=true" biçiminde, gündemdeki gibi
/// "/baslik--123456" değil. Bu yüzden `TopicListParser` bunları kasten eliyor
/// ve ayrı bir ayrıştırıcı gerekiyor.
///
/// Yapı emreisik95/eksilik-os (MIT) projesindeki `DebeParser`'dan alındı.
public enum DebeParser {
    public static func parse(html: String) throws -> [Topic] {
        let document = try SwiftSoup.parse(html)

        var items: [Topic] = []
        var seen = Set<String>()

        for anchor in try document.select("ul.topic-list li a[href*=/entry/]").array() {
            let href = try anchor.attr("href")
            guard let id = entryId(from: href) else { continue }

            // Başlık span.caption içinde; yoksa bağlantının kendi metni.
            let caption = try anchor.select("span.caption").first()?.text().trimmed()
            let fallback = try anchor.text().trimmed()
            let title = (caption?.isEmpty == false) ? (caption ?? fallback) : fallback
            guard !title.isEmpty else { continue }

            guard seen.insert(id).inserted else { continue }
            items.append(
                Topic(id: id, title: title, slug: "", entryCount: "", link: href)
            )
        }

        return items
    }

    /// "/entry/12345?debe=true" -> "12345"
    private static func entryId(from href: String) -> String? {
        guard let range = href.range(of: "/entry/") else { return nil }
        let candidate = String(href[range.upperBound...])
            .components(separatedBy: "?").first ?? ""
        guard !candidate.isEmpty, candidate.allSatisfy(\.isNumber) else { return nil }
        return candidate
    }
}
