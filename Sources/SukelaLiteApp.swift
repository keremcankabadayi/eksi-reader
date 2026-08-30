import SwiftUI

@main
struct SukelaLiteApp: App {
    @AppStorage(AppTheme.storageKey) private var theme: AppTheme = .light

    /// Açılış ekranı kapandı mı.
    @State private var splashDone = false

    init() {
        Appearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                // Açılış ekranı uygulamanın üstünde duruyor: altındaki
                // `task`'lar bu sırada koşuyor, splash bitince liste hazır
                // olmasa bile iskelet satırları karşılıyor.
                if !splashDone {
                    SplashView {
                        withAnimation(.easeOut(duration: 0.35)) { splashDone = true }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            // SF Pro Rounded: uygulamanın her yerinde geçerli.
            .roundedFont()
            // Varsayılan açık tema; ayarlardan değiştirilebiliyor.
            .preferredColorScheme(theme.colorScheme)
            // Menü ve giriş ekranı aynı oturumu paylaşıyor.
            .environmentObject(AuthSession.shared)
            // Oy düğmeleri bütün entry satırlarında aynı tabloya bakıyor.
            .environmentObject(VoteService.shared)
            // Okunmuş entry'ler: liste ve kaydırma destesi aynı kaydı okuyor.
            .environmentObject(ReadTracker.shared)
            // Cloudflare doğrulamasını ilk istek beklemesin diye
            // uygulama açılır açılmaz arka planda başlatıyoruz.
            .task {
                await WebViewFetcher.shared.prewarm()
                // Çerezler silinmişse (WebKit temizliği, 7 günlük imza
                // yenilemesi) menüde "girişli" yazmasın.
                await AuthSession.shared.verifyCookies()
            }
        }
    }
}
