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
    /// Yazar girişi formu.
    case login
    /// Çıkış.
    case logout
    /// Entry oyu (artı/eksi). Gövde POST ile gidiyor.
    case vote
    /// Verilmiş oyu geri alma.
    case removeVote

    public static let baseURL = "https://eksisozluk.com"

    public var url: URL? {
        switch self {
        case let .gundem(page):
            return Self.make(path: "/basliklar/gundem", query: [], page: page)
        case .debe:
            return Self.make(path: "/debe", query: [], page: nil)
        case .login:
            return Self.make(path: "/giris", query: [], page: nil)
        case .logout:
            return Self.make(path: "/terk", query: [], page: nil)
        case .vote:
            return Self.make(path: "/entry/vote", query: [], page: nil)
        case .removeVote:
            return Self.make(path: "/entry/removevote", query: [], page: nil)
        case let .topic(link, page):
            let (path, query) = Self.split(link)
            guard let page else {
                // Sayfa belirtmedik: bağlantı nereye işaret ediyorsa oraya.
                return Self.make(path: path, query: query, page: nil)
            }
            return Self.make(path: path, query: Self.pinned(query, to: page), page: nil)
        }
    }

    /// `focusto=<entry id>` bir konum: sayfa numarasıyla birlikte anlamsız,
    /// sunucu p'yi yok sayıp o entry'nin sayfasına yönlendiriyor.
    ///
    /// `a=popular` ise bir kip, atılmıyor: başlığın kaç sayfa olduğunu
    /// belirliyor (aynı başlık popüler kipte 63, tümünde 64 sayfa). Atarsak
    /// sayfa değiştirince liste bambaşka bir evrene atlıyor. `p` açıkça
    /// yazıldığında Ekşi kipi koruyup istenen sayfayı veriyor.
    private static let positionParameters: Set<String> = ["focusto"]

    /// Sayfayı biz seçtiğimizde `p` her zaman yazılıyor (birinci sayfa dahil),
    /// konum parametreleri atılıyor, diğerlerine dokunulmuyor.
    private static func pinned(_ query: [URLQueryItem], to page: Int) -> [URLQueryItem] {
        var items = query.filter { item in
            let name = item.name.lowercased()
            return name != "p" && !positionParameters.contains(name)
        }
        items.append(URLQueryItem(name: "p", value: String(page)))
        return items
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
