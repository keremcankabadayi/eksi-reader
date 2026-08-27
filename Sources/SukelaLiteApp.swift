import SwiftUI

@main
struct SukelaLiteApp: App {
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .light

    var body: some Scene {
        WindowGroup {
            RootView()
                // Varsayılan açık tema; ayarlardan değiştirilebiliyor.
                .preferredColorScheme(theme.colorScheme)
                // Cloudflare doğrulamasını ilk istek beklemesin diye
                // uygulama açılır açılmaz arka planda başlatıyoruz.
                .task { await WebViewFetcher.shared.prewarm() }
        }
    }
}
