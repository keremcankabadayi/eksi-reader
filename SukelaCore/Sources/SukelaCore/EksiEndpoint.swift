import Foundation

/// Ekşi'deki yolları kuruyor. Saf mantık, ağ yok — test edilebilir.
public enum EksiEndpoint: Hashable, Sendable {
    case gundem(page: Int = 1)
    case debe
    /// Başlık listesinden gelen göreli bağlantı, örneğin "/foo--123".
    case topic(link: String, page: Int = 1)

    public static let baseURL = "https://eksisozluk.com"

    public var path: String {
        switch self {
        case .gundem:
            return "/basliklar/gundem"
        case .debe:
            return "/debe"
        case let .topic(link, _):
            // Bağlantı sorgu taşıyorsa atıyoruz; sayfa parametresini biz ekliyoruz.
            return link.components(separatedBy: "?").first ?? link
        }
    }

    public var page: Int {
        switch self {
        case let .gundem(page): return page
        case .debe: return 1
        case let .topic(_, page): return page
        }
    }

    public var url: URL? {
        var components = URLComponents(string: Self.baseURL + path)
        if page > 1 {
            components?.queryItems = [URLQueryItem(name: "p", value: String(page))]
        }
        return components?.url
    }
}
