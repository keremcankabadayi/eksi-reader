import Combine
import Foundation
import SukelaCore

/// Okunmuş entry/başlık kaydı.
///
/// Debe'de kaydırarak ilerlerken hangi entry'yi geçtiğin belli olsun diye:
/// açılan entry okundu sayılıyor, listede ve kaydırma destesinde okunmamış
/// olanlar öne çıkıyor.
///
/// Kayıt `UserDefaults`'ta duruyor, App Group'ta değil: widget'ın bu
/// bilgiye ihtiyacı yok. Anahtar `Topic.id` (entry/başlık bağlantısı);
/// debe listesi her gün değiştiği için kayıt sınırlı tutuluyor.
@MainActor
final class ReadTracker: ObservableObject {
    static let shared = ReadTracker()

    /// Kaç kayıt saklanıyor. Debe günde 50 entry; yaklaşık iki haftalık
    /// geçmiş yetiyor, ötesi listede zaten görünmüyor.
    private static let capacity = 800
    private static let storageKey = "readTopicIDs"

    /// Okunmuşlar. Sıra önemli: sınır dolunca en eskisi düşüyor.
    @Published private(set) var ids: [String] = []
    private var index: Set<String> = []

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = defaults.stringArray(forKey: Self.storageKey) ?? []
        index = Set(ids)
    }

    func isRead(_ topic: Topic) -> Bool {
        index.contains(topic.id)
    }

    /// Okunmamışların sayısı; ilerleme göstergeleri buna bakıyor.
    func unreadCount(in topics: [Topic]) -> Int {
        topics.reduce(into: 0) { total, topic in
            if !index.contains(topic.id) { total += 1 }
        }
    }

    func markRead(_ topic: Topic) {
        guard !index.contains(topic.id) else { return }
        index.insert(topic.id)
        ids.append(topic.id)
        if ids.count > Self.capacity {
            let excess = ids.count - Self.capacity
            index.subtract(ids.prefix(excess))
            ids.removeFirst(excess)
        }
        persist()
    }

    func markUnread(_ topic: Topic) {
        guard index.contains(topic.id) else { return }
        index.remove(topic.id)
        ids.removeAll { $0 == topic.id }
        persist()
    }

    func toggle(_ topic: Topic) {
        isRead(topic) ? markUnread(topic) : markRead(topic)
    }

    /// Ayarlardaki "okundu işaretlerini sıfırla".
    func clear() {
        ids = []
        index = []
        persist()
    }

    private func persist() {
        defaults.set(ids, forKey: Self.storageKey)
    }
}
