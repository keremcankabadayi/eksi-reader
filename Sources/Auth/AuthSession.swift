import Foundation
import WebKit
import SukelaCore

/// Yazar oturumu.
///
/// Şifreyi biz görmüyoruz: giriş Ekşi'nin kendi `/giris` sayfasında, gömülü
/// bir `WKWebView` içinde yapılıyor. Geriye kalan tek şey çerezler ve onları
/// WebKit'in kendi deposu (`WKWebsiteDataStore.default()`) diskte tutuyor —
/// bütün isteklerimiz zaten o deponun içinden geçtiği için ayrıca bir yere
/// kopyalamıyoruz.
///
/// Burada saklanan tek şey "girişli miyiz, nick ne" bilgisi; çerez değil.
@MainActor
final class AuthSession: ObservableObject {
    static let shared = AuthSession()

    @Published private(set) var isLoggedIn: Bool
    @Published private(set) var nick: String?

    private static let loggedInKey = "authLoggedIn"
    private static let nickKey = "authNick"

    /// Ekşi'nin oturum çerezleri.
    private static let authCookieNames: Set<String> = [".AspNetCore.Cookies", "a"]
    private static let domainSuffix = "eksisozluk.com"

    private init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: Self.loggedInKey)
        nick = UserDefaults.standard.string(forKey: Self.nickKey)
    }

    /// Giriş ekranı oturumu açtı.
    func signedIn(nick: String?) {
        isLoggedIn = true
        if let nick, !nick.isEmpty { self.nick = nick }
        persist()
        AppLog.info("giriş yapıldı: \(self.nick ?? "-")")
        // Gizli tarayıcı sayfayı girişsizken yüklemişti; çerezler ortak ama
        // sayfanın kendi durumu bayat. Bir sonraki istek yeniden kuruyor.
        WebViewFetcher.shared.reset()
    }

    /// Elimize geçen bir sayfadan oturum durumunu tazeliyor. Üst menüsü
    /// olmayan sayfalar (parça HTML) hiçbir şey söylemiyor, es geçiliyor.
    func apply(html: String) {
        guard let state = try? AuthParser.parse(html: html), !state.isIndeterminate else { return }

        if isLoggedIn && !state.isLoggedIn {
            AppLog.warn("oturum sunucuda kapanmış")
            clear()
            return
        }

        guard state.isLoggedIn else { return }
        isLoggedIn = true
        if let parsed = state.nick, !parsed.isEmpty { nick = parsed }
        persist()
    }

    /// Çıkış: Ekşi'ye `/terk` diyip elimizdeki çerezleri siliyoruz.
    func signOut() async {
        if let url = EksiEndpoint.logout.url {
            _ = try? await WebViewFetcher.shared.fetch(url)
        }
        await Self.deleteCookies()
        clear()
        WebViewFetcher.shared.reset()
        AppLog.info("çıkış yapıldı")
    }

    /// Uygulama açılırken: çerez kalmamışsa oturum da yok.
    func verifyCookies() async {
        guard isLoggedIn else { return }
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        let hasAuth = cookies.contains {
            Self.authCookieNames.contains($0.name) && !$0.value.isEmpty
        }
        guard !hasAuth else { return }
        AppLog.warn("oturum çerezi yok, giriş düşürüldü")
        clear()
    }

    private func clear() {
        isLoggedIn = false
        nick = nil
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(isLoggedIn, forKey: Self.loggedInKey)
        if let nick {
            UserDefaults.standard.set(nick, forKey: Self.nickKey)
        } else {
            UserDefaults.standard.removeObject(forKey: Self.nickKey)
        }
    }

    private static func deleteCookies() async {
        let store = WKWebsiteDataStore.default().httpCookieStore
        for cookie in await store.allCookies()
        where cookie.domain.lowercased().hasSuffix(domainSuffix) {
            await store.deleteCookie(cookie)
        }
        for cookie in HTTPCookieStorage.shared.cookies ?? []
        where cookie.domain.lowercased().hasSuffix(domainSuffix) {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
}
