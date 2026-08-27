import Foundation

/// Tarayıcıdan alınmış tek çerez.
public struct SessionCookie: Codable, Hashable, Sendable {
    public let name: String
    public let value: String
    public let domain: String
    public let path: String
    public let expiresAt: Date?

    public init(name: String, value: String, domain: String, path: String, expiresAt: Date?) {
        self.name = name
        self.value = value
        self.domain = domain
        self.path = path
        self.expiresAt = expiresAt
    }

    public func isValid(at date: Date) -> Bool {
        guard let expiresAt else { return true }
        return expiresAt > date
    }
}

/// Uygulamanın `WKWebView`'ından alınan Cloudflare anahtarı.
///
/// Widget'ta tarayıcı yok, JS doğrulamasını çözemiyor. Uygulama doğrulamayı
/// bir kez geçtikten sonra çerezleri ve tarayıcı kimliğini buraya bırakıyor;
/// widget aynı kimlikle düz HTTP isteği atıp gündemi kendi çekiyor.
/// Çerez `User-Agent`'a bağlı, o yüzden ikisi birlikte taşınıyor.
public struct SessionSnapshot: Codable, Hashable, Sendable {
    public let userAgent: String
    public let cookies: [SessionCookie]
    public let updatedAt: Date

    public init(userAgent: String, cookies: [SessionCookie], updatedAt: Date) {
        self.userAgent = userAgent
        self.cookies = cookies
        self.updatedAt = updatedAt
    }

    /// Süresi dolmamış çerezlerden `Cookie` başlığı.
    public func cookieHeader(at date: Date = Date()) -> String? {
        let live = cookies.filter { $0.isValid(at: date) }
        guard !live.isEmpty else { return nil }
        return live.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }

    /// Cloudflare'ın kapıyı açan çerezi elimizde mi?
    public var hasClearance: Bool {
        cookies.contains { $0.name == "cf_clearance" }
    }
}

/// `session.json`: uygulama yazıyor, widget okuyor.
public enum SessionStore {
    private static let fileName = "session.json"

    public static func fileURL(in container: URL) -> URL {
        container.appendingPathComponent(fileName)
    }

    public static func write(_ snapshot: SessionSnapshot, to container: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(snapshot).write(to: fileURL(in: container), options: .atomic)
    }

    public static func read(from container: URL) throws -> SessionSnapshot {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(
            SessionSnapshot.self,
            from: try Data(contentsOf: fileURL(in: container))
        )
    }
}
