import SwiftUI
import SukelaCore

/// Entry gövdesi: bkz bağlantıları ve linkler tıklanabilir.
///
/// HTML'i doğrudan render etmiyoruz (eksilik-os `NSAttributedString`'in HTML
/// içe aktarıcısını kullanıyor, entry başına pahalı). Ayrıştırma SukelaCore'da
/// segmentlere ayrılıyor, burada yalnızca `AttributedString` kuruluyor.
struct EntryBodyView: View {
    let segments: [EntrySegment]
    let fontSize: Double
    /// Site içi bağlantı tıklandığında çağrılıyor: başlık yolu ve gösterilen ad.
    let openInApp: (String, String) -> Void

    var body: some View {
        Text(attributed)
            .font(.system(size: fontSize))
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction { url in
                // Site içi bağlantılar uygulamada açılıyor; profil ve harici
                // bağlantılar sisteme bırakılıyor.
                guard let link = EntryLink.classify(href: url.absoluteString),
                      let inAppLink = link.inAppLink else { return .systemAction }
                openInApp(inAppLink, label(for: url))
                return .handled
            })
    }

    private var attributed: AttributedString {
        var result = AttributedString()
        for segment in segments {
            var piece = AttributedString(segment.text)
            if let url = segment.link?.url {
                piece.link = url
                piece.foregroundColor = .accentColor
            }
            result.append(piece)
        }
        return result
    }

    /// Açılan başlığın adı: bağlantının gövdedeki metni. Sayfa yüklenene kadar
    /// üst barda bunu gösteriyoruz.
    private func label(for url: URL) -> String {
        segments.first { $0.link?.url == url }?.text
            .replacingOccurrences(of: EntryContent.externalMarker, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
