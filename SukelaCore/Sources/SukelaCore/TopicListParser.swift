import Foundation
import SwiftSoup

/// Gündem / debe gibi başlık listesi sayfalarını ayrıştırıyor.
///
/// Seçiciler emreisik95/eksilik-os (MIT) projesinden alındı.
public enum TopicListParser {
    /// Dardan genişe. Ekşi işaretlemeyi zaman zaman değiştiriyor, ilk tutan
    /// desende duruyoruz. En gevşek desen entry listesini de yakalayabildiği
    /// için `isTopicList` ve `topicId` süzgeçleri şart.
    private static let listSelectors = [
        "ul.topic-list.partial.mobile",
        "ul.topic-list.partial",
        "ul[class*=topic-list]",
        "section#content-body ul",
    ]

    public static func parse(html: String) throws -> [Topic] {
        let document = try SwiftSoup.parse(html)

        for selector in listSelectors {
            let lists = try document.select(selector).array().filter(isTopicList)
            guard !lists.isEmpty else { continue }

            var topics: [Topic] = []
            var seen = Set<String>()
            for list in lists {
                for anchor in try list.select("li a").array() {
                    guard let topic = try makeTopic(from: anchor) else { continue }
                    guard seen.insert(topic.id).inserted else { continue }
                    topics.append(topic)
                }
            }
            if !topics.isEmpty { return topics }
        }

        return []
    }

    /// Entry listesinin sınıfı da "topic-list" ile başlıyor
    /// (`<ul id="entry-item-list" class="topic-list entry-list">`), bu yüzden
    /// sınıf adına bakmak yetmiyor.
    private static func isTopicList(_ list: Element) -> Bool {
        let id = (try? list.attr("id")) ?? ""
        if id.hasPrefix("entry-item-list") { return false }

        let classNames = (try? list.attr("class")) ?? ""
        if classNames.contains("entry-list") { return false }

        return true
    }

    private static func makeTopic(from element: Element) throws -> Topic? {
        let href = try element.attr("href")
        guard let topicId = topicId(from: href) else { return nil }

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

        let slug = href.components(separatedBy: "--").first?
            .replacingOccurrences(of: "/", with: "") ?? ""

        return Topic(id: topicId, title: title, slug: slug, entryCount: entryCount, link: href)
    }

    /// Başlık bağlantısı "/bir-baslik--123456" biçiminde. Yazar profilleri
    /// ("/biri/kerem"), entry kalıcı bağlantıları ("/entry/98765") ve kanal
    /// bağlantıları ("/basliklar/kanal/spor") bu deseni taşımıyor.
    private static func topicId(from href: String) -> String? {
        guard let range = href.range(of: "--", options: .backwards) else { return nil }
        let candidate = String(href[range.upperBound...])
            .components(separatedBy: "?").first ?? ""
        guard !candidate.isEmpty, candidate.allSatisfy(\.isNumber) else { return nil }
        return candidate
    }
}

extension String {
    func trimmed() -> String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
