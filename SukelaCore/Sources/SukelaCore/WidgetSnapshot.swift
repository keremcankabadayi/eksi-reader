import Foundation

/// Widget'ın gösterdiği tek başlık.
public struct WidgetTopic: Codable, Hashable, Sendable, Identifiable {
    public let title: String
    public let entryCount: String
    /// Göreli yol; widget dokunulduğunda uygulama bunu açıyor.
    public let link: String

    public var id: String { link }

    public init(title: String, entryCount: String, link: String) {
        self.title = title
        self.entryCount = entryCount
        self.link = link
    }

    public init(_ topic: Topic) {
        self.init(title: topic.title, entryCount: topic.entryCount, link: topic.link)
    }
}

/// Widget'a bırakılan gündem listesi.
///
/// Widget kendi başına Ekşi'den veri çekemiyor: Cloudflare'ı `WKWebView` ile
/// aşıyoruz, extension'da WebView yok. Uygulama gündemi her çektiğinde bunu
/// paylaşılan alana yazıyor, widget okuyor.
public struct WidgetSnapshot: Codable, Hashable, Sendable {
    public let topics: [WidgetTopic]
    public let updatedAt: Date

    public init(topics: [WidgetTopic], updatedAt: Date) {
        self.topics = topics
        self.updatedAt = updatedAt
    }
}

/// Uygulama ile widget arasındaki dosya. App Group container'ında duruyor.
public enum WidgetStore {
    public static let appGroup = "group.com.kerem.sukelalite"
    private static let fileName = "gundem.json"
    /// Widget dar; uzun listeyi taşımanın anlamı yok.
    public static let topicLimit = 12

    public static func fileURL(in container: URL) -> URL {
        container.appendingPathComponent(fileName)
    }

    public static func encode(_ snapshot: WidgetSnapshot) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(snapshot)
    }

    public static func decode(_ data: Data) throws -> WidgetSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WidgetSnapshot.self, from: data)
    }

    public static func write(_ snapshot: WidgetSnapshot, to container: URL) throws {
        try encode(snapshot).write(to: fileURL(in: container), options: .atomic)
    }

    public static func read(from container: URL) throws -> WidgetSnapshot {
        try decode(try Data(contentsOf: fileURL(in: container)))
    }

    /// Başlık listesinden widget'a yazılacak anlık görüntü.
    public static func snapshot(from topics: [Topic], at date: Date) -> WidgetSnapshot {
        WidgetSnapshot(
            topics: topics.prefix(topicLimit).map(WidgetTopic.init),
            updatedAt: date
        )
    }
}
