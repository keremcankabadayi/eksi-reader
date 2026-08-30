import Combine
import Foundation
import SukelaCore

enum FavoriteError: LocalizedError {
    case badEndpoint
    case notLoggedIn
    /// Sunucu isteği aldı ama kabul etmedi; metin varsa Ekşi'nin kendi metni.
    case rejected(String?)

    var errorDescription: String? {
        switch self {
        case .badEndpoint:
            return "Favori adresi kurulamadı."
        case .notLoggedIn:
            return "Favorilemek için giriş yapman gerekiyor."
        case let .rejected(message):
            return message ?? "Favori kaydedilmedi."
        }
    }
}

/// Entry favorileri.
///
/// `VoteService` ile aynı düzen: gerçek kaynak sayfanın kendisi, Ekşi
/// favoride olup olmadığını entry'nin özniteliğinde söylüyor
/// (`Entry.isFavorite`). Burada tutulan tablo yalnızca taze sayfayı
/// beklemeyen üstyazım — düğmeye basınca damla hemen dolsun diye.
@MainActor
final class FavoriteService: ObservableObject {
    static let shared = FavoriteService()

    /// Sunucudan gelen değeri geçici olarak örten durum.
    struct State: Equatable {
        var isFavorite: Bool
        var count: Int
    }

    @Published private(set) var overrides: [String: State] = [:]
    @Published private(set) var pending: Set<String> = []
    /// Son hata; ekran gösterip temizliyor.
    @Published var failure: String?

    private init() {}

    /// Önce üstyazım, yoksa sayfanın söylediği.
    func state(for entry: Entry) -> State {
        overrides[entry.id]
            ?? State(isFavorite: entry.isFavorite, count: entry.favoriteCount)
    }

    func isPending(_ entryId: String) -> Bool { pending.contains(entryId) }

    /// Favorideyse çıkarıyor, değilse ekliyor.
    func toggle(entry: Entry) async {
        let id = entry.id
        guard !pending.contains(id) else { return }
        guard AuthSession.shared.isLoggedIn else {
            failure = FavoriteError.notLoggedIn.localizedDescription
            return
        }

        let current = state(for: entry)
        let adding = !current.isFavorite
        // Sitenin kendi JS'i de sayıyı istek dönmeden oynatıyor; gerçek
        // sayıyı sunucu yanıtta söylüyor, geldiğinde üstüne yazıyoruz.
        let optimistic = State(
            isFavorite: adding,
            count: max(0, current.count + (adding ? 1 : -1))
        )

        pending.insert(id)
        overrides[id] = optimistic
        defer { pending.remove(id) }

        do {
            let count = try await submit(entryId: id, adding: adding)
            overrides[id] = State(isFavorite: adding, count: count ?? optimistic.count)
            AppLog.info("favori \(id): \(adding ? "eklendi" : "çıkarıldı")")
        } catch {
            // Sunucu hayır dedi: sayfanın söylediğine geri dön.
            overrides[id] = nil
            failure = error.localizedDescription
            AppLog.warn("favori düştü \(id): \(error.localizedDescription)")

            if (error as? FavoriteParseError) == .notLoggedIn {
                // Oturum sunucuda kapanmış; menüdeki durumu tazeleyelim.
                await AuthSession.shared.refreshIdentity()
            }
        }
    }

    /// Taze sayfa geldi: artık sunucu ne diyorsa o. Uçuşta olanların
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

    /// Sitenin kendi JS'i ile aynı istek: `/entry/favla` eklerken,
    /// `/entry/favlama` çıkarırken; gövde ikisinde de yalnız `entryId`.
    /// Dönen değer sunucunun söylediği yeni sayı.
    private func submit(entryId: String, adding: Bool) async throws -> Int? {
        let endpoint: EksiEndpoint = adding ? .addFavorite : .removeFavorite
        guard let url = endpoint.url else { throw FavoriteError.badEndpoint }

        let page = try await WebViewFetcher.shared.post(url, form: ["entryId": entryId])
        let result = try FavoriteParser.parse(json: page.html)
        guard result.success else { throw FavoriteError.rejected(result.message) }
        return result.count
    }
}
