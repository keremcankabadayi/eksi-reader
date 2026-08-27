import Foundation

/// Ekşi'deki yolları kuruyor. Saf mantık, ağ yok — test edilebilir.
public enum EksiEndpoint: Hashable, Sendable {
    case gundem(page: Int = 1)
    case debe
    /// Başlık listesinden gelen göreli bağlantı, örneğin "/foo--123?a=popular".
    ///
    /// `page` nil ise bağlantının kendi sorgusu olduğu gibi korunuyor. Ekşi
    /// gündemde, daha önce açtığın başlık için "nereden devam edeceğin"
    /// bilgisini sorguda veriyor; atarsak başlık hep baştan açılıyor.
    case topic(link: String, page: Int? = nil)

    public static let baseURL = "https://eksisozluk.com"

    public var url: URL? {
        switch self {
        case let .gundem(page):
            return Self.make(path: "/basliklar/gundem", query: [], page: page)
        case .debe:
            return Self.make(path: "/debe", query: [], page: nil)
        case let .topic(link, page):
            let (path, query) = Self.split(link)
            return Self.make(path: path, query: query, page: page)
        }
    }

    /// "/foo--123?a=popular&p=5" -> ("/foo--123", [a=popular, p=5])
    private static func split(_ link: String) -> (String, [URLQueryItem]) {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed) else {
            let path = trimmed.components(separatedBy: "?").first ?? trimmed
            return (path, [])
        }
        return (components.path, components.queryItems ?? [])
    }

    /// `page` verilmişse bağlantıdaki `p` onunla değiştiriliyor; verilmemişse
    /// bağlantı ne diyorsa o kalıyor. Diğer parametrelere dokunulmuyor.
    private static func make(path: String, query: [URLQueryItem], page: Int?) -> URL? {
        var components = URLComponents(string: baseURL)
        components?.path = path

        var items = query
        if let page {
            items.removeAll { $0.name.caseInsensitiveCompare("p") == .orderedSame }
            if page > 1 {
                items.append(URLQueryItem(name: "p", value: String(page)))
            }
        }
        components?.queryItems = items.isEmpty ? nil : items

        return components?.url
    }
}
