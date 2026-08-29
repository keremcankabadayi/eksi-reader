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
/// Ekşi oyu sayfada göstermiyor (kimin ne verdiği listede yok), o yüzden
/// buradaki tablo yalnızca **bu oturumda bu uygulamadan** verilen oyları
/// tutuyor. Uygulama kapanınca sıfırlanıyor; sunucudaki oy duruyor.
///
/// İstek iyimser: düğmeye basınca renk hemen değişiyor, sunucu hayır derse
/// eski hâline dönüyor.
@MainActor
final class VoteService: ObservableObject {
    static let shared = VoteService()

    @Published private(set) var votes: [String: VoteDirection] = [:]
    @Published private(set) var pending: Set<String> = []
    /// Son hata; ekran gösterip temizliyor.
    @Published var failure: String?

    /// ASP.NET antiforgery anahtarı. Oturum başına sabit, bir kez alıp
    /// saklıyoruz; reddedilirse tazeleniyor.
    private var token: String?

    private init() {}

    func direction(for entryId: String) -> VoteDirection? { votes[entryId] }

    func isPending(_ entryId: String) -> Bool { pending.contains(entryId) }

    /// Aynı yöne ikinci kez basmak oyu geri alıyor.
    func toggle(entry: Entry, direction: VoteDirection) async {
        let id = entry.id
        guard !pending.contains(id) else { return }
        guard AuthSession.shared.isLoggedIn else {
            failure = VoteError.notLoggedIn.localizedDescription
            return
        }

        let previous = votes[id]
        let target: VoteDirection? = previous == direction ? nil : direction

        pending.insert(id)
        votes[id] = target
        defer { pending.remove(id) }

        do {
            try await submit(entryId: id, ownerId: entry.author.id, target: target, canRetry: true)
            AppLog.info("oy \(id): \(target.map { String($0.rawValue) } ?? "geri alındı")")
        } catch {
            votes[id] = previous
            failure = error.localizedDescription
            AppLog.warn("oy düştü \(id): \(error.localizedDescription)")
        }
    }

    /// Çıkış yapıldı ya da oturum düştü: eldeki tablo artık bu kullanıcıya ait
    /// değil.
    func clear() {
        votes.removeAll()
        pending.removeAll()
        token = nil
    }

    /// Ekşi'nin oy uçları form gövdesi bekliyor: `id` entry, `owner` yazar,
    /// `rate` yön. Geri alma `rate` almıyor.
    private func submit(
        entryId: String,
        ownerId: String,
        target: VoteDirection?,
        canRetry: Bool
    ) async throws {
        let endpoint: EksiEndpoint = target == nil ? .removeVote : .vote
        guard let url = endpoint.url else { throw VoteError.badEndpoint }

        var form = ["id": entryId, "owner": ownerId]
        if let target { form["rate"] = String(target.rawValue) }
        if let token = await verificationToken() {
            form["__RequestVerificationToken"] = token
        }

        let page = try await WebViewFetcher.shared.post(url, form: form)

        let result: VoteResult
        do {
            result = try VoteParser.parse(json: page.html)
        } catch {
            // JSON yerine sayfa geldi. İki ihtimal: anahtar bayat ya da oturum
            // düşmüş. Anahtarı bir kez tazeleyip yeniden deniyoruz; o istek de
            // sayfa döndürürse oturum durumunu sayfadan okuyup pes ediyoruz.
            guard canRetry else {
                AuthSession.shared.apply(html: page.html)
                throw error
            }
            token = nil
            return try await submit(
                entryId: entryId,
                ownerId: ownerId,
                target: target,
                canRetry: false
            )
        }

        guard result.success else { throw VoteError.rejected(result.message) }
    }

    /// Anahtar ana sayfadan okunuyor. Bulunamazsa istek anahtarsız gidiyor:
    /// uç anahtar istemiyorsa çalışıyor, istiyorsa sunucunun kendi metni
    /// hatayı zaten anlatıyor.
    private func verificationToken() async -> String? {
        if let token { return token }
        guard let url = URL(string: EksiEndpoint.baseURL + "/") else { return nil }
        guard let page = try? await WebViewFetcher.shared.fetch(url) else { return nil }

        // Sayfa elimize geçmişken oturum durumunu da tazeliyoruz.
        AuthSession.shared.apply(html: page.html)

        token = VoteParser.verificationToken(html: page.html)
        if token == nil { AppLog.warn("antiforgery anahtarı bulunamadı") }
        return token
    }
}
