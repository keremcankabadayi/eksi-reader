import Foundation
import SwiftSoup

/// Entry gövdesindeki bir bağlantının nereye gittiği.
///
/// Sınıflandırma eksilik-os'un `InternalLinkPolicy`'sinden alındı: site içi
/// bağlantılar uygulamada açılıyor, geri kalanı sisteme bırakılıyor.
public enum EntryLink: Hashable, Sendable {
    /// Site içi başlık. "/?q=deneme" (bkz araması) ya da "/deneme--123".
    case topic(link: String)
    case entry(id: String)
    case profile(nick: String)
    case external(url: String)

    /// Uygulama içinde başlık sayfası olarak açılabiliyorsa bağlantı yolu.
    /// Profil sayfasında entry listesi yok, orayı sisteme bırakıyoruz.
    public var inAppLink: String? {
        switch self {
        case let .topic(link): return link
        case let .entry(id): return "/entry/\(id)"
        case .profile, .external: return nil
        }
    }

    public var url: URL? {
        switch self {
        case let .topic(link):
            return EksiEndpoint.topic(link: link).url
        case let .entry(id):
            return URL(string: "\(EksiEndpoint.baseURL)/entry/\(id)")
        case let .profile(nick):
            var components = URLComponents(string: EksiEndpoint.baseURL)
            components?.path = "/biri/\(nick)"
            return components?.url
        case let .external(url):
            // Gövdedeki adres kaçışsız gelebiliyor (boşluk, Türkçe harf); ham hali
            // nil dönerse `URL` kurulamıyor ve bağlantı tıklanamaz oluyor.
            if let direct = URL(string: url) { return direct }
            return url
                .addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)
                .flatMap(URL.init(string:))
        }
    }

    private static let internalHosts: Set<String> = ["eksisozluk.com", "www.eksisozluk.com"]

    /// Bir `href`'i hedefe çeviriyor. Tanıyamadığında nil.
    public static func classify(href: String) -> EntryLink? {
        let raw = href.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, raw != "#" else { return nil }
        guard let components = URLComponents(string: raw) else { return nil }

        if let scheme = components.scheme?.lowercased() {
            guard scheme == "http" || scheme == "https" else { return .external(url: raw) }
            guard let host = components.host?.lowercased(),
                  internalHosts.contains(host) else { return .external(url: raw) }
        } else if let host = components.host?.lowercased() {
            // "//example.com/x" gibi protokolsüz bağlantı.
            guard internalHosts.contains(host) else { return .external(url: raw) }
        }

        let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let query = components.percentEncodedQuery.map { "?\($0)" } ?? ""

        // "/?q=deneme": bkz araması. Ekşi bunu başlığa yönlendiriyor.
        if path.isEmpty {
            guard !query.isEmpty else { return nil }
            return .topic(link: "/\(query)")
        }

        let parts = path.split(separator: "/").map(String.init)
        guard !parts.contains("..") else { return nil }

        if parts.first == "entry", parts.count == 2, Int(parts[1]) != nil {
            return .entry(id: parts[1])
        }
        if parts.first == "biri", parts.count == 2 {
            let nick = parts[1].removingPercentEncoding ?? parts[1]
            return nick.isEmpty ? nil : .profile(nick: nick)
        }

        return .topic(link: "/\(path)\(query)")
    }

    /// "deneme" -> "/?q=deneme". Gizli yıldız bkz'leri buradan bağlanıyor.
    public static func lookupLink(for query: String) -> String? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        guard let encoded = components.percentEncodedQuery, !encoded.isEmpty else { return nil }
        return "/?\(encoded)"
    }
}

/// Gövdenin bir parçası: düz metin ya da bağlantı.
public struct EntrySegment: Hashable, Sendable {
    public let text: String
    public let link: EntryLink?

    public init(text: String, link: EntryLink? = nil) {
        self.text = text
        self.link = link
    }
}

/// Entry gövdesini bağlantılarıyla birlikte parçalara ayırıyor.
///
/// `EntryText.plainText` linkleri düşürüyor; burada `bkz` bağlantıları ve
/// harici linkler korunuyor. Görüntüleme katmanı bunlardan tıklanabilir metin
/// kuruyor — HTML'i doğrudan render etmiyoruz, entry başına maliyeti yüksek.
public enum EntryContent {
    /// Harici bağlantıların sonuna konan işaret; eksilik-os'taki gibi.
    public static let externalMarker = "\u{2197}\u{FE0E}"

    public static func segments(from html: String) -> [EntrySegment] {
        guard let document = try? SwiftSoup.parseBodyFragment(html),
              let body = document.body() else {
            return [EntrySegment(text: html)]
        }
        document.outputSettings().prettyPrint(pretty: false)

        var segments: [EntrySegment] = []
        walk(body, into: &segments)
        return normalized(segments)
    }

    private static func walk(_ node: Node, into segments: inout [EntrySegment]) {
        for child in node.getChildNodes() {
            if let text = child as? TextNode {
                append(text.getWholeText(), link: nil, to: &segments)
                continue
            }
            guard let element = child as? Element else { continue }

            switch element.tagName().lowercased() {
            case "br":
                append("\n", link: nil, to: &segments)
            case "a":
                appendAnchor(element, to: &segments)
            case "sup":
                appendStar(element, to: &segments)
            case "p", "div", "li":
                walk(element, into: &segments)
                append("\n", link: nil, to: &segments)
            default:
                walk(element, into: &segments)
            }
        }
    }

    private static func appendAnchor(_ element: Element, to segments: inout [EntrySegment]) {
        let label = (try? element.text()) ?? ""
        guard !label.isEmpty else { return }

        // Ekşi bazı bağlantıları href yerine data-query ile veriyor.
        let dataQuery = (try? element.attr("data-query")) ?? ""
        let href = (try? element.attr("href")) ?? ""
        let target = dataQuery.isEmpty ? href : (EntryLink.lookupLink(for: dataQuery) ?? "")

        guard let link = EntryLink.classify(href: target) else {
            append(label, link: nil, to: &segments)
            return
        }

        if case .external = link {
            append("\(label) \(externalMarker)", link: link, to: &segments)
        } else {
            append(label, link: link, to: &segments)
        }
    }

    /// `<sup><a data-query="x">*</a></sup>`: gövdede yıldız olarak duran gizli
    /// bkz. Yıldız tek başına hiçbir şey anlatmıyor, açık yazıyoruz.
    private static func appendStar(_ element: Element, to segments: inout [EntrySegment]) {
        guard let anchor = try? element.select("a[data-query]").first(),
              let query = try? anchor.attr("data-query"),
              !query.trimmingCharacters(in: .whitespaces).isEmpty,
              let lookup = EntryLink.lookupLink(for: query) else {
            walk(element, into: &segments)
            return
        }
        append(" (bkz: ", link: nil, to: &segments)
        append(query, link: .topic(link: lookup), to: &segments)
        append(")", link: nil, to: &segments)
    }

    private static func append(_ text: String, link: EntryLink?, to segments: inout [EntrySegment]) {
        guard !text.isEmpty else { return }
        let cleaned = text.replacingOccurrences(of: "\u{00A0}", with: " ")

        // Ardışık düz metinleri birleştiriyoruz; gereksiz parça olmasın.
        if link == nil, let last = segments.last, last.link == nil {
            segments[segments.count - 1] = EntrySegment(text: last.text + cleaned)
            return
        }
        segments.append(EntrySegment(text: cleaned, link: link))
    }

    private static func normalized(_ segments: [EntrySegment]) -> [EntrySegment] {
        var result = segments

        // Baştaki ve sondaki boşluk/satır sonları gövdeye ait değil.
        if let first = result.first, first.link == nil {
            result[0] = EntrySegment(text: String(first.text.drop(while: { $0.isWhitespace })))
        }
        if let last = result.last, last.link == nil {
            var text = last.text
            while let character = text.last, character.isWhitespace { text.removeLast() }
            result[result.count - 1] = EntrySegment(text: text)
        }

        return result.filter { !$0.text.isEmpty }
    }
}

public extension Entry {
    /// Gövdenin bağlantılarıyla birlikte parçalanmış hali.
    var segments: [EntrySegment] {
        EntryContent.segments(from: contentHTML)
    }
}
