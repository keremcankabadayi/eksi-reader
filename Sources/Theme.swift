import SwiftUI

/// Renkler Şükela Reader'ın (App Store) ekran görüntülerinden alındı:
/// yeşil kimlik rengi, turuncu bağlantılar.
enum Palette {
    /// Üst bar, yazar nick'i, entry sayısı.
    static let green = Color(red: 0x3D / 255, green: 0xBE / 255, blue: 0x8B / 255)
    /// bkz ve linkler. Yeşille karışmasın diye ayrı renk.
    static let orange = Color(red: 0xE8 / 255, green: 0xA3 / 255, blue: 0x3D / 255)
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
}
