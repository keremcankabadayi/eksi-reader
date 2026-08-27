import SwiftUI
import UIKit

/// Renkler Şükela Reader'ın (App Store) ekran görüntülerinden alındı:
/// yeşil kimlik rengi, turuncu bağlantılar.
enum Palette {
    /// Üst bar, yazar nick'i, entry sayısı.
    static let green = Color(red: 0x3D / 255, green: 0xBE / 255, blue: 0x8B / 255)
    /// bkz ve linkler. Yeşille karışmasın diye ayrı renk.
    static let orange = Color(red: 0xE8 / 255, green: 0xA3 / 255, blue: 0x3D / 255)

    /// Zebra satırların zemini. Açık temada yeşile çalan çok hafif gri,
    /// koyu temada hafif beyaz. `Color.primary.opacity` yerine sabit renk:
    /// açık temada gri, satırı kirletmeden ayırıyor.
    static let zebra = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.06)
            : UIColor(red: 0xEC / 255, green: 0xF3 / 255, blue: 0xEF / 255, alpha: 1)
    })

    /// Zebranın diğer yarısı: normal zemin.
    static let base = Color(uiColor: .systemBackground)

    /// Satır sırasına göre zemin. Liste ve widget aynı kuralı kullanıyor.
    static func row(isEven: Bool) -> Color {
        isEven ? base : zebra
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
                colorScheme == .dark ? Color.black : Palette.green,
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
