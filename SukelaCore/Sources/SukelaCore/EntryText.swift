import Foundation
import SwiftSoup

/// Entry gövdesini okunabilir düz metne çeviriyor.
///
/// Ekşi gövdeleri HTML: `<br>` satır sonu, `bkz` bağlantıları, resim linkleri.
/// Zengin render (tıklanabilir bkz'ler) sonraki iş; şimdilik metni doğru
/// göstermek yeterli. Gövdenin HTML hali `Entry.contentHTML`'de duruyor,
/// bu dönüşüm kayıplı ve geri dönülmez değil.
public enum EntryText {
    public static func plainText(from html: String) -> String {
        guard let document = try? SwiftSoup.parseBodyFragment(html) else {
            return html
        }

        // SwiftSoup text() bütün boşlukları tek boşluğa indiriyor ve <br>'i
        // yok sayıyor. Satır sonlarını korumak için önce işaretliyoruz.
        if let brs = try? document.select("br") {
            for br in brs.array() {
                try? br.after("\n")
            }
        }
        if let paragraphs = try? document.select("p") {
            for paragraph in paragraphs.array() {
                try? paragraph.after("\n")
            }
        }

        guard let text = try? document.text(trimAndNormaliseWhitespace: false) else {
            return html
        }

        return text
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension Entry {
    /// Gövdenin düz metin hali. Görüntüleme katmanı için.
    var plainText: String {
        EntryText.plainText(from: contentHTML)
    }
}
