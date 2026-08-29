import Combine
import Foundation
import SukelaCore

enum VoteError: LocalizedError {
    case badEndpoint
    case notLoggedIn
    /// Sunucu isteği aldı ama kabul etmedi; metin varsa Ekşi'nin kendi metni.
    case rejected(String?)

    var errorDescription: String? {
        switch self {
        case .badEndpoint:
            return "Oy adresi kurulamadı."
        case .notLoggedIn:
            return "Oy vermek için giriş yapman gerekiyor."
        case let .rejected(message):
            return message ?? "Oy kaydedilmedi."
        }
    }
}

/// Entry oyları.
///
/// Kaynak sayfanın kendisi: Ekşi verilmiş oyu entry'nin özniteliğinde
/// söylüyor (`Entry.vote`), yani uygulama kapanıp açılınca oy yerinde
/// duruyor. Burada tutulan tablo yalnızca **taze sayfayı beklemeyen**
/// üstyazım: düğmeye basınca renk hemen değişsin diye. Sayfa yeniden
/// çekildiğinde sunucunun dediği geçerli oluyor.
@MainActor
final class VoteService: ObservableObject {
    static let shared = VoteService()

    /// Sunucudan gelen değeri geçici olarak örten oylar.
    ///
    /// Değer kasten iki katlı optional: anahtar yoksa "üstyazım yok",
    /// anahtar varken nil ise "oy geri alındı" demek.
    @Published private(set) var overrides: [String: VoteDirection?] = [:]
    @Published private(set) var pending: Set<String> = []
    /// Son hata; ekran gösterip temizliyor.
    @Published var failure: String?

    private init() {}

    /// Önce üstyazım, yoksa sayfanın söylediği.
    func direction(for entry: Entry) -> VoteDirection? {
        if let override = overrides[entry.id] { return override }
        return entry.vote
    }

    func isPending(_ entryId: String) -> Bool { pending.contains(entryId) }

    /// Aynı yöne ikinci kez basmak oyu geri alıyor.
    func toggle(entry: Entry, direction: VoteDirection) async {
        let id = entry.id
        guard !pending.contains(id) else { return }
        guard AuthSession.shared.isLoggedIn else {
            failure = VoteError.notLoggedIn.localizedDescription
            return
        }

        let current = self.direction(for: entry)
        let target: VoteDirection? = current == direction ? nil : direction

        pending.insert(id)
        overrides[id] = .some(target)
        defer { pending.remove(id) }

        do {
            try await submit(
                entryId: id,
                ownerId: entry.author.id,
                rate: direction,
                removing: target == nil
            )
            AppLog.info("oy \(id): \(target.map { String($0.rawValue) } ?? "geri alındı")")
        } catch {
            // Sunucu hayır dedi: sayfanın söylediğine geri dön.
            overrides[id] = nil
            failure = error.localizedDescription
            AppLog.warn("oy düştü \(id): \(error.localizedDescription)")

            if (error as? VoteParseError) == .notLoggedIn {
                // Oturum sunucuda kapanmış; menüdeki durumu tazeleyelim.
                await AuthSession.shared.refreshIdentity()
            }
        }
    }

    /// Taze sayfa geldi: artık sunucu ne diyorsa o. Uçuşta olan oyların
    /// üstyazımı duruyor, o istek daha bitmedi.
    func adopt(_ entries: [Entry]) {
        for entry in entries where !pending.contains(entry.id) {
            overrides[entry.id] = nil
        }
    }

    /// Çıkış yapıldı ya da oturum düştü.
    func clear() {
        overrides.removeAll()
        pending.removeAll()
    }

    /// Sitenin kendi JS'i ile aynı istek: `/entry/vote` oy verirken,
    /// `/entry/removevote` geri alırken; gövde ikisinde de `id`, `rate`,
    /// `owner`.
    private func submit(
        entryId: String,
        ownerId: String,
        rate: VoteDirection,
        removing: Bool
    ) async throws {
        // Geri alırken de rate gidiyor ve basılan okun yönünü taşıyor:
        // sunucu hangi oyun kaldırıldığını bundan biliyor.
        let endpoint: EksiEndpoint = removing ? .removeVote : .vote
        guard let url = endpoint.url else { throw VoteError.badEndpoint }

        let form = ["id": entryId, "owner": ownerId, "rate": String(rate.rawValue)]

        let page = try await WebViewFetcher.shared.post(url, form: form)
        let result = try VoteParser.parse(json: page.html)
        guard result.success else { throw VoteError.rejected(result.message) }
    }
}
