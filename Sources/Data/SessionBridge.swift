import Foundation
import WebKit
import WidgetKit
import SukelaCore

/// Cloudflare anahtarını widget'a veriyor.
///
/// Widget'ta tarayıcı yok, doğrulamayı orada geçemiyoruz. Uygulama
/// doğrulamayı geçtikten sonra çerezleri ve tarayıcı kimliğini App Group'a
/// bırakıyor; widget aynı kimlikle gündemi kendi çekiyor.
@MainActor
enum SessionBridge {
    /// Çerezlerin hepsi değil, Ekşi'ye ait olanlar.
    private static let domainSuffix = "eksisozluk.com"

    static func publish(from webView: WKWebView) async {
        guard let container = AppGroupContainer.url else {
            AppLog.warn("widget: App Group yok, oturum paylaşılamadı")
            return
        }

        let userAgent = (try? await webView.evaluateJavaScript("navigator.userAgent")) as? String
        let cookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
            .filter { $0.domain.hasSuffix(domainSuffix) }
            .map {
                SessionCookie(
                    name: $0.name,
                    value: $0.value,
                    domain: $0.domain,
                    path: $0.path,
                    expiresAt: $0.expiresDate
                )
            }

        guard let userAgent, !cookies.isEmpty else {
            AppLog.warn("widget: çerez ya da tarayıcı kimliği alınamadı")
            return
        }

        let snapshot = SessionSnapshot(
            userAgent: userAgent,
            cookies: cookies,
            updatedAt: Date()
        )

        do {
            try SessionStore.write(snapshot, to: container)
            WidgetCenter.shared.reloadAllTimelines()
            AppLog.info(
                "widget: oturum paylaşıldı (\(cookies.count) çerez,"
                + " clearance: \(snapshot.hasClearance ? "var" : "yok"))"
            )
        } catch {
            AppLog.warn("widget: oturum yazılamadı — \(error.localizedDescription)")
        }
    }
}
