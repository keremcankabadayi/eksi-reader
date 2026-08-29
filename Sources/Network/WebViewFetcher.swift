import Foundation
import WebKit
import SukelaCore

enum FetchError: LocalizedError {
    case cloudflareBlocked
    case noWindow
    case badResponse
    case httpStatus(Int)
    case javaScript(String)

    var errorDescription: String? {
        switch self {
        case .cloudflareBlocked:
            return "Cloudflare doğrulaması geçilemedi. Birazdan tekrar dene."
        case .noWindow:
            return "Uygulama penceresi bulunamadı."
        case .badResponse:
            return "Sunucudan beklenmeyen yanıt geldi."
        case let .httpStatus(code):
            return "Sunucu \(code) döndü."
        case let .javaScript(detail):
            return "Sayfa içi istek düştü: \(detail)"
        }
    }
}

/// Ekşi Cloudflare arkasında; düz `URLSession` isteği 403 alıyor.
///
/// Çözüm: gizli bir `WKWebView` açıp challenge'ı gerçek WebKit'e çözdürmek,
/// sonraki istekleri de sayfanın kendi JS bağlamında `fetch()` ile atmak.
/// Böylece TLS parmak izi, çerezler ve tarayıcıya ait başlıklar gerçek oluyor.
///
/// Yaklaşım emreisik95/eksilik-os (MIT) projesinden alındı.
@MainActor
final class WebViewFetcher: NSObject {
    static let shared = WebViewFetcher()

    private var webView: WKWebView?
    private var hostWindow: UIWindow?
    private var isReady = false
    private var isBootstrapping = false
    private var waiters: [CheckedContinuation<Bool, Never>] = []
    private var mainFrameStatusCode: Int?
    private var mainFrameHeaders: [String: String] = [:]
    private var timeoutTask: Task<Void, Never>?
    private var bootstrapStart: ContinuousClock.Instant?

    private static let bootstrapTimeout: Duration = .seconds(30)

    private override init() { super.init() }

    /// callAsyncJavaScript hatayı yutup "A JavaScript exception occurred"
    /// diyor; gerçek mesaj userInfo içinde duruyor.
    private static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        var parts = ["\(nsError.domain) \(nsError.code): \(nsError.localizedDescription)"]
        for key in [
            "WKJavaScriptExceptionMessage",
            "WKJavaScriptExceptionSourceURL",
            "WKJavaScriptExceptionLineNumber",
            "WKJavaScriptExceptionColumnNumber",
        ] where nsError.userInfo[key] != nil {
            parts.append("\(key)=\(nsError.userInfo[key]!)")
        }
        return parts.joined(separator: " | ")
    }

    // MARK: - Public

    /// Uygulama açılır açılmaz çağrılıyor. Cloudflare doğrulaması ilk isteğin
    /// içinde değil, kullanıcı daha sekmeye bakarken arka planda bitiyor.
    func prewarm() async {
        _ = await bootstrap()
    }

    /// Oturum değişti (giriş/çıkış): eldeki sayfa bayat, bir sonraki istek
    /// tarayıcıyı yeniden kuruyor.
    func reset() {
        AppLog.info("tarayıcı sıfırlandı")
        invalidate()
    }

    func fetch(_ url: URL, headers: [String: String] = [:]) async throws -> FetchedPage {
        try await send(url, method: "GET", body: nil, headers: headers)
    }

    /// Form gövdeli POST. Oy vermek gibi yazma işlemleri buradan geçiyor:
    /// çerezi, Referer'ı ve TLS parmak izini yine tarayıcı koyuyor.
    ///
    /// Ekşi bu uçlarda XHR bekliyor; her çağıran ayrı ayrı uğraşmasın diye
    /// başlıkları burada ekliyoruz.
    func post(
        _ url: URL,
        form: [String: String],
        headers: [String: String] = [:]
    ) async throws -> FetchedPage {
        var requestHeaders = [
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
            "X-Requested-With": "XMLHttpRequest",
            "Accept": "application/json, text/javascript, */*; q=0.01",
        ]
        requestHeaders.merge(headers) { _, override in override }
        return try await send(url, method: "POST", body: Self.encode(form), headers: requestHeaders)
    }

    /// `application/x-www-form-urlencoded` gövdesi.
    private static func encode(_ form: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return form
            .sorted { $0.key < $1.key }
            .map { pair in
                let key = pair.key.addingPercentEncoding(withAllowedCharacters: allowed) ?? pair.key
                let value = pair.value.addingPercentEncoding(withAllowedCharacters: allowed)
                    ?? pair.value
                return "\(key)=\(value)"
            }
            .joined(separator: "&")
    }

    private func send(
        _ url: URL,
        method: String,
        body: String?,
        headers: [String: String]
    ) async throws -> FetchedPage {
        let started = ContinuousClock.now
        guard await Stopwatch.measure("bootstrap beklendi", { await bootstrap() }) else {
            throw FetchError.cloudflareBlocked
        }

        var response = try await runFetch(url, method: method, body: body, headers: headers)
        if CloudflareChallenge.isChallenge(headers: response.headers, html: response.body) {
            AppLog.warn("challenge yakalandı, oturum yenileniyor")
            // Challenge yanıtı isteğin uygulamaya hiç ulaşmadığı anlamına
            // geliyor; POST'u tekrarlamak da bu yüzden güvenli.
            invalidate()
            guard await bootstrap() else { throw FetchError.cloudflareBlocked }
            response = try await runFetch(url, method: method, body: body, headers: headers)
        }

        guard (200...299).contains(response.status) else {
            throw FetchError.httpStatus(response.status)
        }
        AppLog.info("çekme toplam \(url.lastPathComponent): \(started.duration(to: .now).milliseconds)")
        return FetchedPage(url: url, status: response.status, html: response.body)
    }

    // MARK: - Bootstrap

    private func bootstrap() async -> Bool {
        if isReady, webView != nil { return true }

        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
            guard !isBootstrapping else { return }
            isBootstrapping = true
            startBootstrap()
        }
    }

    private func startBootstrap() {
        AppLog.info("bootstrap başlıyor")
        bootstrapStart = .now
        mainFrameStatusCode = nil
        mainFrameHeaders = [:]

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844),
            configuration: configuration
        )
        webView.navigationDelegate = self
        self.webView = webView

        // WebKit görünmeyen bir web view'ın JS'ini kısıtlıyor; gerçek bir
        // pencereye bağlamak zorundayız. Neredeyse şeffaf ve dokunulamaz.
        guard attachHostWindow(for: webView) else {
            finishBootstrap(success: false)
            return
        }

        guard let url = URL(string: EksiEndpoint.baseURL + "/") else {
            finishBootstrap(success: false)
            return
        }
        webView.load(URLRequest(url: url))

        timeoutTask = Task { [weak self] in
            try? await Task.sleep(for: Self.bootstrapTimeout)
            guard !Task.isCancelled else { return }
            self?.finishBootstrap(success: false)
        }
    }

    private func finishBootstrap(success: Bool) {
        guard isBootstrapping else { return }
        isBootstrapping = false
        isReady = success
        timeoutTask?.cancel()
        timeoutTask = nil

        if !success { invalidate() }

        let elapsed = bootstrapStart.map { $0.duration(to: .now).milliseconds } ?? "-"
        bootstrapStart = nil
        if success {
            AppLog.info("bootstrap tamam: \(elapsed)")
            // Cloudflare anahtarını widget'a bırakıyoruz: widget gündemi
            // kendi çekiyor ama doğrulamayı burada geçiyoruz.
            if let webView {
                Task { await SessionBridge.publish(from: webView) }
            }
        } else {
            AppLog.warn("bootstrap başarısız: \(elapsed)")
        }
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume(returning: success) }
    }

    private func invalidate() {
        isReady = false
        webView?.stopLoading()
        webView = nil
        hostWindow?.isHidden = true
        hostWindow = nil
    }

    private func attachHostWindow(for webView: WKWebView) -> Bool {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive })
                ?? scenes.first else {
            return false
        }

        let controller = UIViewController()
        controller.view.backgroundColor = .clear
        webView.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: controller.view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
        ])

        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.rootViewController = controller
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue - 1)
        window.alpha = 0.01
        window.isUserInteractionEnabled = false
        window.accessibilityElementsHidden = true
        window.isHidden = false
        hostWindow = window
        return true
    }

    // MARK: - In-page fetch

    private struct RawResponse {
        let status: Int
        let headers: [String: String]
        let body: String
    }

    /// İsteği sayfanın içinde çalıştırıyor. Çerez, User-Agent, TLS parmak izi —
    /// hepsini tarayıcı kendi koyuyor, biz karışmıyoruz.
    private static let fetchScript = """
    try {
      const options = {
        method: method,
        credentials: 'include',
        redirect: 'follow',
        headers: requestHeaders
      };
      // GET/HEAD gövde kabul etmiyor, null vermek bile TypeError atıyor.
      if (body !== null && method !== 'GET' && method !== 'HEAD') {
        options.body = body;
      }
      const response = await fetch(url, options);
      const responseHeaders = {};
      response.headers.forEach((value, key) => { responseHeaders[key] = value; });
      return {
        ok: true,
        status: response.status,
        headers: responseHeaders,
        body: await response.text()
      };
    } catch (error) {
      // Hatayı fırlatmıyoruz: callAsyncJavaScript onu yutup yerine
      // "A JavaScript exception occurred" diyor. Veri olarak döndürünce
      // gerçek mesaj günlüğe düşüyor.
      return {
        ok: false,
        name: String(error && error.name),
        message: String(error && error.message ? error.message : error),
        stack: String(error && error.stack ? error.stack : '-')
      };
    }
    """

    private func runFetch(
        _ url: URL,
        method: String,
        body: String?,
        headers: [String: String]
    ) async throws -> RawResponse {
        guard let webView else { throw FetchError.cloudflareBlocked }

        let requestStart = ContinuousClock.now
        let value: Any?
        do {
            value = try await webView.callAsyncJavaScript(
                Self.fetchScript,
                arguments: [
                    "url": url.absoluteString,
                    "method": method,
                    // callAsyncJavaScript Optional kabul etmiyor; JS tarafında
                    // null görünsün diye NSNull veriyoruz.
                    "body": body ?? NSNull(),
                    "requestHeaders": headers,
                ],
                in: nil,
                contentWorld: .page
            )
        } catch {
            AppLog.error("JS çağrısı düştü: \(Self.describe(error))")
            throw FetchError.javaScript(Self.describe(error))
        }

        guard let dictionary = value as? [String: Any] else {
            AppLog.error("JS yanıtı sözlük değil: \(String(describing: value))")
            throw FetchError.badResponse
        }

        if dictionary["ok"] as? Bool == false {
            let name = dictionary["name"] as? String ?? "-"
            let message = dictionary["message"] as? String ?? "-"
            let stack = dictionary["stack"] as? String ?? "-"
            AppLog.error("fetch() JS hatası: \(name): \(message)\n\(stack)")
            throw FetchError.javaScript("\(name): \(message)")
        }

        guard let status = dictionary["status"] as? Int,
              let body = dictionary["body"] as? String else {
            AppLog.error("JS yanıtında status/body yok: \(dictionary.keys.sorted())")
            throw FetchError.badResponse
        }
        AppLog.info(
            "fetch \(url.absoluteString) -> HTTP \(status), \(body.count) karakter,"
            + " \(requestStart.duration(to: .now).milliseconds)"
        )

        let rawHeaders = dictionary["headers"] as? [String: Any] ?? [:]
        let headers = rawHeaders.reduce(into: [String: String]()) { result, pair in
            result[pair.key] = String(describing: pair.value)
        }
        return RawResponse(status: status, headers: headers, body: body)
    }
}

// MARK: - WKNavigationDelegate

extension WebViewFetcher: WKNavigationDelegate {
    nonisolated func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(.allow)
        guard navigationResponse.isForMainFrame,
              let response = navigationResponse.response as? HTTPURLResponse else { return }

        let statusCode = response.statusCode
        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, pair in
            guard let key = pair.key as? String else { return }
            result[key] = String(describing: pair.value)
        }

        Task { @MainActor [weak self] in
            guard let self, self.webView === webView else { return }
            self.mainFrameStatusCode = statusCode
            self.mainFrameHeaders = headers
        }
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor [weak self] in
            guard let self, self.webView === webView else { return }

            let title = (try? await webView.evaluateJavaScript("document.title")) as? String ?? ""
            let html = (try? await webView.evaluateJavaScript(
                "document.documentElement.outerHTML"
            )) as? String ?? ""

            guard self.webView === webView else { return }

            // Challenge sürüyorsa sayfa birkaç kez yeniden yükleniyor;
            // hazır olana kadar bekliyoruz, zaman aşımı bizi kurtarıyor.
            guard CloudflareChallenge.isReady(
                statusCode: self.mainFrameStatusCode,
                headers: self.mainFrameHeaders,
                title: title,
                html: html
            ) else { return }

            self.finishBootstrap(success: true)
        }
    }

    nonisolated func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        Task { @MainActor [weak self] in
            guard let self, self.webView === webView else { return }
            self.finishBootstrap(success: false)
        }
    }
}
