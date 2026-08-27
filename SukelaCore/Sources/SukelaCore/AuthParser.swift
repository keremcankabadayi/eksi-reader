import Foundation
import SwiftSoup

/// Sayfadaki üst menüden okunan oturum durumu.
public struct AuthState: Equatable, Sendable {
    public let isLoggedIn: Bool
    /// Girişliyse yazar nick'i.
    public let nick: String?
    /// Sayfada üst menü hiç yok (kısmi HTML, hata sayfası): bu sayfa oturum
    /// hakkında bir şey söylemiyor, eldeki duruma dokunma.
    public let isIndeterminate: Bool

    public init(isLoggedIn: Bool, nick: String?, isIndeterminate: Bool) {
        self.isLoggedIn = isLoggedIn
        self.nick = nick
        self.isIndeterminate = isIndeterminate
    }
}

/// Üst menüden oturum durumunu çıkarıyor.
///
/// Seçiciler emreisik95/eksilik-os (MIT) projesinden alındı: girişliyken
/// menüde `li.buddy` içinde profil bağlantısı, girişsizken `#top-login-link`
/// duruyor.
///
/// Nick için gövdedeki `/biri/...` bağlantılarına bakmıyoruz; entry yazarları
/// da aynı yola gidiyor, hepsini "giriş yapmış kullanıcı" sanardık.
public enum AuthParser {
    private static let profileSelectors = [
        "li.buddy a[href^=/biri/]",
        "li.mobile-only.buddy a[href^=/biri/]",
        "#top-profile-link",
    ]

    private static let loginSelectors = [
        "#top-login-link",
        "a[href^=/giris]",
    ]

    public static func parse(html: String) throws -> AuthState {
        let document = try SwiftSoup.parse(html)

        let profile = try first(in: document, matching: profileSelectors)
        let login = try first(in: document, matching: loginSelectors)

        guard profile != nil || login != nil else {
            return AuthState(isLoggedIn: false, nick: nil, isIndeterminate: true)
        }

        guard let profile, login == nil else {
            return AuthState(isLoggedIn: false, nick: nil, isIndeterminate: false)
        }

        return AuthState(isLoggedIn: true, nick: try nick(from: profile), isIndeterminate: false)
    }

    private static func first(in document: Document, matching selectors: [String]) throws -> Element? {
        for selector in selectors {
            if let element = try document.select(selector).first() { return element }
        }
        return nil
    }

    /// Önce `title`, sonra bağlantı metni, olmazsa yoldaki nick.
    private static func nick(from element: Element) throws -> String? {
        let title = try element.attr("title").trimmed()
        if !title.isEmpty { return title }

        let text = try element.text().trimmed()
        // "hesabım" gibi genel etiketler nick değil.
        if !text.isEmpty, !["hesabım", "profil", "profilim"].contains(text.lowercased()) {
            return text
        }

        let href = try element.attr("href")
        guard href.hasPrefix("/biri/") else { return nil }
        let slug = href.dropFirst("/biri/".count).split(separator: "?", maxSplits: 1).first
        guard let slug, !slug.isEmpty else { return nil }
        return String(slug).removingPercentEncoding ?? String(slug)
    }
}
