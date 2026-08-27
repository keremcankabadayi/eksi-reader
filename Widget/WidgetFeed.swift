import Foundation
import SukelaCore

/// Widget gündemi kendi çekiyor.
///
/// Extension'da `WKWebView` yok, Cloudflare'ın JS doğrulamasını burada
/// çözemiyoruz — `/basliklar/gundem` düz istekte `cf-mitigated: challenge`
/// ile 403 dönüyor. Uygulama doğrulamayı bir kez geçince çerezleri ve
/// tarayıcı kimliğini App Group'a bırakıyor; widget aynı kimlikle istek
/// atınca Cloudflare kapıyı açıyor. Yani veri widget'ın kendi isteğinden
/// geliyor, uygulamanın listesinden değil.
enum WidgetFeed {
    struct Result {
        let topics: [WidgetTopic]
        let updatedAt: Date
        /// Ağdan mı geldi, yoksa elimizdeki son kopya mı?
        let isLive: Bool
    }

    static func load() async -> Result? {
        let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetStore.appGroup
        )

        if let container,
           let session = try? SessionStore.read(from: container),
           let topics = await fetchGundem(with: session) {
            // Tazeyi elimizde de tutuyoruz: anahtar bayatlarsa gösterecek
            // bir şey kalsın.
            let snapshot = WidgetSnapshot(topics: topics, updatedAt: Date())
            try? WidgetStore.write(snapshot, to: container)
            return Result(topics: topics, updatedAt: snapshot.updatedAt, isLive: true)
        }

        guard let container, let cached = try? WidgetStore.read(from: container) else { return nil }
        return Result(topics: cached.topics, updatedAt: cached.updatedAt, isLive: false)
    }

    private static func fetchGundem(with session: SessionSnapshot) async -> [WidgetTopic]? {
        guard let url = EksiEndpoint.gundem().url,
              let cookies = session.cookieHeader() else { return nil }

        var request = URLRequest(url: url)
        // Çerez User-Agent'a bağlı: uygulamanın tarayıcısı ne diyorsa aynısı.
        request.setValue(session.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(cookies, forHTTPHeaderField: "Cookie")
        request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        request.setValue("tr-TR,tr;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue(EksiEndpoint.baseURL + "/", forHTTPHeaderField: "Referer")
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalCacheData

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let html = String(data: data, encoding: .utf8),
              let topics = try? TopicListParser.parse(html: html),
              !topics.isEmpty else { return nil }

        return topics.prefix(WidgetStore.topicLimit).map(WidgetTopic.init)
    }
}
