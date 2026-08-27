import Foundation
import SukelaCore

/// Son çekilen başlık listesi diskte.
///
/// Açılışta bekleme Cloudflare doğrulaması + istek + ayrıştırmadan geliyor,
/// hepsi ağa bağlı. Listeyi saklayınca uygulama açılır açılmaz dünkü gündemi
/// gösteriyor, taze liste arkada gelince yerine geçiyor.
enum FeedCache {
    /// Caches: sistem sıkışınca silebilir, sorun değil — yeniden çekiyoruz.
    private static var directory: URL? {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    }

    private static func fileURL(for feed: Feed) -> URL? {
        directory?.appendingPathComponent("feed-\(feed.rawValue).json")
    }

    /// Diskteki liste. Dosya yoksa ya da biçim değiştiyse nil.
    static func read(_ feed: Feed) -> [Topic]? {
        guard let url = fileURL(for: feed),
              let data = try? Data(contentsOf: url),
              let topics = try? JSONDecoder().decode([Topic].self, from: data),
              !topics.isEmpty else { return nil }
        return topics
    }

    static func write(_ topics: [Topic], for feed: Feed) {
        guard !topics.isEmpty, let url = fileURL(for: feed) else { return }
        do {
            try JSONEncoder().encode(topics).write(to: url, options: .atomic)
        } catch {
            AppLog.warn("önbellek yazılamadı (\(feed.rawValue)): \(error.localizedDescription)")
        }
    }
}
