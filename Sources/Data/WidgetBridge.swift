import Foundation
import WidgetKit
import SukelaCore

/// Gündemi widget'ın okuyabileceği yere yazıyor.
///
/// Widget kendi başına veri çekemiyor (Cloudflare'ı `WKWebView` ile aşıyoruz,
/// extension'da WebView yok), o yüzden uygulama her gündem çekişinde son
/// listeyi App Group'a bırakıyor.
enum WidgetBridge {
    static func publish(_ topics: [Topic]) {
        guard !topics.isEmpty else { return }
        guard let container = AppGroupContainer.url else {
            // Ücretsiz imzada App Group hiç verilmemiş olabiliyor; widget o
            // zaman boş kalıyor, uygulama çalışmaya devam ediyor.
            AppLog.warn("widget: App Group yok, gündem paylaşılamadı")
            return
        }

        do {
            try WidgetStore.write(WidgetStore.snapshot(from: topics, at: Date()), to: container)
            WidgetCenter.shared.reloadAllTimelines()
            AppLog.info("widget: \(min(topics.count, WidgetStore.topicLimit)) başlık paylaşıldı")
        } catch {
            AppLog.warn("widget: yazılamadı — \(error.localizedDescription)")
        }
    }
}
