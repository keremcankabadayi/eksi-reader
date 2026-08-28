import SwiftUI
import WebKit
import SukelaCore

/// Yazar girişi.
///
/// Formu biz çizmiyoruz: Ekşi'nin kendi `/giris` sayfası gömülü bir tarayıcıda
/// açılıyor. Şifre uygulamaya hiç uğramıyor, captcha ve iki adımlı doğrulama
/// gibi ne varsa sitenin kendi akışında kalıyor. Giriş bitince tek aldığımız
/// şey çerezler — onlar da WebKit'in ortak deposunda duruyor, veri çeken
/// gizli tarayıcı aynı depoyu kullandığı için istekler girişli oluyor.
///
/// Yaklaşım emreisik95/eksilik-os (MIT) projesinden alındı.
struct LoginView: View {
    let onSuccess: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            LoginWebView { nick in
                onSuccess(nick)
                dismiss()
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("yazar girişi")
            .navigationBarTitleDisplayMode(.inline)
            .eksiNavigationBar()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("vazgeç") { dismiss() }
                }
            }
        }
    }
}

private struct LoginWebView: UIViewRepresentable {
    let onSuccess: (String?) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Gizli tarayıcıyla aynı depo: giriş çerezleri oraya da geçiyor.
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        if let url = EksiEndpoint.login.url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        private let onSuccess: (String?) -> Void
        private var finished = false

        init(onSuccess: @escaping (String?) -> Void) {
            self.onSuccess = onSuccess
        }

        /// Her sayfa yüklendiğinde iki şeye bakıyoruz: oturum çerezi düştü mü,
        /// üst menüde profil bağlantısı çıktı mı.
        ///
        /// Asıl kanıt çerez. Ekşi giriş sonrası nereye yönlendirirse
        /// yönlendirsin, üst menüyü hangi işaretlemeyle çizerse çizsin tutuyor;
        /// yalnızca menüye bakmak yetmiyordu, giriş oluyor ama uygulama
        /// girişsiz sanıyordu. Menü ayrıştırması artık yalnızca nick için.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard !finished else { return }
            let currentURL = webView.url

            webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, _ in
                guard let self, !self.finished else { return }
                let state = try? AuthParser.parse(html: result as? String ?? "")

                webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                    guard !self.finished else { return }

                    let hasAuthCookie = cookies.contains { cookie in
                        AuthSession.authCookieNames.contains(cookie.name) && !cookie.value.isEmpty
                    }
                    // Form hâlâ ekrandaysa iş bitmemiştir: /giris ilk
                    // açıldığında da elimizde çerez olabilir.
                    let onLoginPage = currentURL?.path.hasPrefix("/giris") ?? false

                    guard state?.isLoggedIn == true || (hasAuthCookie && !onLoginPage) else { return }

                    self.finished = true
                    self.onSuccess(state?.nick)
                }
            }
        }
    }
}
