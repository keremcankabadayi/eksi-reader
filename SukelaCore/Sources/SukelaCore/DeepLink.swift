import Foundation

/// Widget'tan uygulamaya geçiş. Widget yalnızca URL açabiliyor; başlığı
/// hangi bağlantıdan açacağımızı bu URL taşıyor.
public enum DeepLink: Hashable, Sendable {
    case topic(link: String, title: String)

    public static let scheme = "sukela"

    public var url: URL? {
        switch self {
        case let .topic(link, title):
            var components = URLComponents()
            components.scheme = Self.scheme
            components.host = "topic"
            components.queryItems = [
                URLQueryItem(name: "link", value: link),
                URLQueryItem(name: "title", value: title),
            ]
            return components.url
        }
    }

    public static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme?.lowercased() == scheme,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host?.lowercased() == "topic" else { return nil }

        let items = components.queryItems ?? []
        guard let link = items.first(where: { $0.name == "link" })?.value,
              !link.isEmpty else { return nil }
        let title = items.first(where: { $0.name == "title" })?.value ?? ""
        return .topic(link: link, title: title)
    }
}
