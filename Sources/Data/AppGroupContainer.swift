import Foundation
#if canImport(Security)
import Security
#endif
import SukelaCore

/// Uygulama ile widget'ın buluştuğu klasör.
///
/// `project.yml`'de istediğimiz grup `group.com.kerem.sukelalite`, ama
/// ücretsiz imzada isteğimiz aynen verilmiyor: SideStore/AltStore App
/// Group'u kendi takım kimliğiyle yeniden adlandırıp öyle imzalıyor.
/// Sabit ismi aramak o yüzden "App Group yok" ile dönüyor. Önce sabit ismi
/// deniyoruz, tutmazsa imzanın gerçekten verdiği grupları entitlement'tan
/// okuyup sırayla deniyoruz.
enum AppGroupContainer {
    /// Bir kez çözülüyor; her yazmada entitlement okumanın anlamı yok.
    static let resolved: (id: String, url: URL)? = {
        for id in candidates() {
            if let url = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: id
            ) {
                return (id, url)
            }
        }
        return nil
    }()

    static var url: URL? { resolved?.url }
    /// Hangi grup tuttu? Ayarlar ekranında gösteriyoruz.
    static var identifier: String? { resolved?.id }

    /// İstediğimiz isim önce, imzanın verdikleri sonra; tekrarlar atılıyor.
    private static func candidates() -> [String] {
        var seen = Set<String>()
        return ([WidgetStore.appGroup] + granted()).filter { seen.insert($0).inserted }
    }

    /// Binary'nin entitlement'ındaki `application-groups` listesi.
    private static func granted() -> [String] {
        #if canImport(Security)
        guard let task = SecTaskCreateFromSelf(nil),
              let value = SecTaskCopyValueForEntitlement(
                  task,
                  "com.apple.security.application-groups" as CFString,
                  nil
              ),
              let groups = value as? [String] else { return [] }
        // Bizimkine benzeyen varsa o öne geçsin; başka uygulamanın grubuna
        // yazmanın anlamı yok.
        let ours = groups.filter { $0.contains("sukelalite") }
        return ours.isEmpty ? groups : ours
        #else
        return []
        #endif
    }
}
