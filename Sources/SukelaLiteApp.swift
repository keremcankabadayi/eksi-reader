import SwiftUI

@main
struct SukelaLiteApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                // Cloudflare doğrulamasını ilk istek beklemesin diye
                // uygulama açılır açılmaz arka planda başlatıyoruz.
                .task { await WebViewFetcher.shared.prewarm() }
        }
    }
}
