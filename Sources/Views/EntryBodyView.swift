import SwiftUI
import UIKit
import SukelaCore

/// Bir entry'nin çizime hazır hali.
///
/// Gövde ayrıştırması (SwiftSoup) ve `AttributedString` kurulumu pahalı;
/// satır her göründüğünde yapılırsa liste yukarı kaydırırken takılıyor.
/// Onun yerine sayfa yüklenirken bir kez hesaplanıyor.
struct RenderedEntry: Identifiable {
    let id: String
    let entry: Entry
    let body: AttributedString
    /// Kopyalama için düz metin.
    let plain: String
    /// Bağlantı URL'sinden gövdedeki metnine; açılan başlığa ad vermek için.
    let labels: [URL: String]

    init(entry: Entry) {
        self.id = entry.id
        self.entry = entry

        var body = AttributedString()
        var labels: [URL: String] = [:]
        for segment in entry.segments {
            var piece = AttributedString(segment.text)
            if let url = segment.link?.url {
                piece.link = url
                piece.foregroundColor = Palette.link
                labels[url] = segment.text
                    .replacingOccurrences(of: EntryContent.externalMarker, with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            body.append(piece)
        }
        self.body = body
        self.plain = String(body.characters)
        self.labels = labels
    }
}

/// Entry gövdesi: bkz bağlantıları ve linkler tıklanabilir.
///
/// HTML'i doğrudan render etmiyoruz (eksilik-os `NSAttributedString`'in HTML
/// içe aktarıcısını kullanıyor, entry başına pahalı); ayrıştırma SukelaCore'da
/// segmentlere ayrılıyor.
struct EntryBodyView: View {
    let rendered: RenderedEntry
    let fontSize: Double
    /// Site içi bağlantı tıklandığında çağrılıyor: başlık yolu ve gösterilen ad.
    let openInApp: (String, String) -> Void

    var body: some View {
        Text(rendered.body)
            .font(.system(size: fontSize))
            .foregroundStyle(Palette.text)
            .frame(maxWidth: .infinity, alignment: .leading)
            // textSelection yerine uzun basınca kopyalama: seçim katmanı uzun
            // metinlerde her ölçümde çalışıp kaydırmayı takıyordu.
            .contextMenu {
                Button {
                    UIPasteboard.general.string = rendered.plain
                } label: {
                    Label("kopyala", systemImage: "doc.on.doc")
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                // Site içi bağlantılar uygulamada açılıyor; profil ve harici
                // bağlantılar sisteme bırakılıyor.
                guard let link = EntryLink.classify(href: url.absoluteString),
                      let inAppLink = link.inAppLink else { return .systemAction }
                openInApp(inAppLink, rendered.labels[url] ?? "")
                return .handled
            })
    }
}
