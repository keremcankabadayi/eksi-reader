import Foundation
import SwiftSoup

/// Gündem / debe gibi başlık listesi sayfalarını ayrıştırıyor.
///
/// Seçiciler emreisik95/eksilik-os (MIT) projesinden alındı; Ekşi zaman zaman
/// işaretlemeyi değiştirdiği için birden fazla desen sırayla deneniyor.
public enum TopicListParser {
    private static let selectors = [
        "ul[class*=topic-list] li a",
        "section#content-body ul li a",
    ]

    public static func parse(html: String) throws -> [Topic] {
        let document = try SwiftSoup.parse(html)

        for selector in selectors {
            let elements = try document.select(selector)
            guard !elements.isEmpty() else { continue }

            var topics: [Topic] = []
            for element in elements.array() {
                guard let topic = try makeTopic(from: element) else { continue }
                topics.append(topic)
            }
            if !topics.isEmpty { return topics }
        }

        return []
    }

    private static func makeTopic(from element: Element) throws -> Topic? {
        let href = try element.attr("href")
        guard !href.isEmpty else { return nil }

        // Entry sayısı başlığın içindeki <small> ya da .detail elemanında.
        let countElement = try element.select("small").first()
            ?? element.select(".detail").first()
        let entryCount = try countElement?.text().trimmed() ?? ""

        // Sayıyı başlıktan ayıklıyoruz; text() ikisini birleştirip veriyor.
        var title = try element.text().trimmed()
        if !entryCount.isEmpty, title.hasSuffix(entryCount) {
            title = String(title.dropLast(entryCount.count)).trimmed()
        }
        guard !title.isEmpty else { return nil }

        // "/bir-baslik--123456" biçiminde; id "--" sonrası, slug öncesi.
        let parts = href.components(separatedBy: "--")
        let slug = parts.first?.replacingOccurrences(of: "/", with: "") ?? ""
        let id = parts.count > 1 ? (parts.last ?? href) : href

        return Topic(id: id, title: title, slug: slug, entryCount: entryCount, link: href)
    }
}

extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
