import Foundation
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

    /// İmzanın gerçekten verdiği gruplar.
    ///
    /// `SecTaskCopyValueForEntitlement` iOS'ta yok (macOS API'si), o yüzden
    /// entitlement'ı imzalanırken pakete konan `embedded.mobileprovision`'dan
    /// okuyoruz: CMS zarfının içinde düz XML plist duruyor.
    private static func granted() -> [String] {
        guard let url = Bundle.main.url(
                  forResource: "embedded",
                  withExtension: "mobileprovision"
              ),
              let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8)) else { return [] }

        let object = try? PropertyListSerialization.propertyList(
            from: data[start.lowerBound..<end.upperBound],
            format: nil
        )

        guard let profile = object as? [String: Any],
              let entitlements = profile["Entitlements"] as? [String: Any],
              let groups = entitlements["com.apple.security.application-groups"] as? [String]
        else { return [] }

        // Bizimkine benzeyen varsa o öne geçsin; başka uygulamanın grubuna
        // yazmanın anlamı yok.
        let ours = groups.filter { $0.contains("sukelalite") }
        return ours.isEmpty ? groups : ours
    }
}
