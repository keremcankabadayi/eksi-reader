import SwiftUI
import UIKit

/// Renkler.
///
/// Açık tema Şükela Reader'ın (App Store) ekran görüntülerinden: yeşil
/// kimlik rengi, turuncu bağlantılar. Koyu tema sıcak ve düşük kontrastlı:
/// kömür zemin, kırık beyaz metin, amber bağlantı, adaçayı nick.
enum Palette {
    /// Kimlik yeşili. Açık temadaki üst bar bunun dolusu.
    static let brand = Color(uiColor: ui(0x3D_BE_8B))

    /// Zemin. Koyuda #1E1E1E.
    static let base = adaptive(light: .systemBackground, dark: ui(0x1E_1E_1E))
    /// Kart / zebra satırı. Koyuda zeminden bir tık açık: #252525.
    static let surface = adaptive(light: ui(0xEC_F3_EF), dark: ui(0x25_25_25))

    /// Gövde metni. Koyuda saf beyaz değil, göz yormayan #D1D1D1.
    static let text = adaptive(light: .label, dark: ui(0xD1_D1_D1))
    /// Tarih ve diğer meta bilgi.
    static let meta = adaptive(light: .secondaryLabel, dark: ui(0x7A_7A_7A))
    /// bkz, linkler, entry sayısı. Koyuda amber, açıkta turuncu.
    static let link = adaptive(light: ui(0xE8_A3_3D), dark: ui(0xCC_A0_46))
    /// Yazar nick'i. Koyuda adaçayı yeşili.
    static let nick = adaptive(light: ui(0x3D_BE_8B), dark: ui(0x66_99_66))

    /// Sabit adaçayı #669966. Temaya göre değişmiyor: entry imzası,
    /// sayfalama okları ve başlıktaki entry sayısı bu renkte.
    static let sage = Color(uiColor: ui(0x66_99_66))

    /// Satır sırasına göre zemin. Liste ve widget aynı kuralı kullanıyor.
    static func row(isEven: Bool) -> Color {
        isEven ? base : surface
    }

    /// 0xRRGGBB.
    private static func ui(_ value: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }
}

/// Görünüm tercihi. Varsayılan açık: telefon koyu temadayken uygulama
/// fazla karanlık kalıyordu.
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    static let storageKey = "appTheme"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "açık"
        case .dark: return "koyu"
        case .system: return "sistem"
        }
    }

    /// `nil` = sisteme uy.
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

/// Sekme çubuğu UIKit çiziyor; SwiftUI'nin `fontDesign`'ı oraya geçmiyor,
/// yazı tipini ayrıca söylüyoruz. Yalnızca font veriliyor, renk ve seçim
/// vurgusu sistemde kalıyor.
enum Appearance {
    static func apply() {
        guard let descriptor = UIFont.systemFont(ofSize: 10, weight: .medium)
            .fontDescriptor.withDesign(.rounded) else { return }
        let font = UIFont(descriptor: descriptor, size: 10)
        UITabBarItem.appearance().setTitleTextAttributes([.font: font], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([.font: font], for: .selected)
    }
}

/// Uygulamanın yazı tipi: San Francisco'nun yuvarlak kesimi (SF Pro
/// Rounded). Ek font dosyası yok, sistemde hazır.
///
/// `fontDesign` iOS 16.1 ile geldi, hedefimiz 16.0: eski sürümde metin
/// varsayılan SF Pro Text kalıyor, düzen bozulmuyor.
private struct RoundedFont: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.1, *) {
            content.fontDesign(.rounded)
        } else {
            content
        }
    }
}

/// Günlük ve teşhis metinleri: hizalama için tek aralıklı kalmalı, kökteki
/// yuvarlak tasarımı burada geri alıyoruz.
private struct MonospacedFont: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.1, *) {
            content.fontDesign(.monospaced)
        } else {
            content
        }
    }
}

/// Üst bar: açık temada dolu yeşil, koyu temada siyah; içeriği her iki
/// durumda da beyaz.
private struct EksiNavigationBar: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .toolbarBackground(
                colorScheme == .dark ? Palette.surface : Palette.brand,
                for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func eksiNavigationBar() -> some View {
        modifier(EksiNavigationBar())
    }

    /// Kökte bir kez: altındaki bütün metinler yuvarlak kesime geçiyor.
    func roundedFont() -> some View {
        modifier(RoundedFont())
    }

    /// Yuvarlak kesimden muaf tutulan yerler (günlük, ham HTML).
    func monospacedFont() -> some View {
        modifier(MonospacedFont())
    }
}
