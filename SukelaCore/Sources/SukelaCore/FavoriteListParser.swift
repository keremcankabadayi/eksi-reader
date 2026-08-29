import Foundation
import SwiftSoup

/// Bir entry'yi favorileyenler.
///
/// Ekşi bu listeyi `/entry/favorileyenler?entryId=…` adresinde parça HTML
/// olarak veriyor; sitenin kendi JS'i de aynı parçayı açılır kutuya basıyor.
/// Sarmalayan işaretleme sürüm sürüm değişiyor, o yüzden kapsayıcıya değil
/// yazar bağlantılarına bakıyoruz: `/biri/<nick>`.
public enum FavoriteListParser {
    public static func parse(html: String) throws -> [String] {
        let document = try SwiftSoup.parse(html)
        var nicks: [String] = []
        var seen: Set<String> = []

        for anchor in try document.select("a[href^=/biri/]").array() {
            guard let parsed = try nick(from: anchor), !seen.contains(parsed) else { continue }
            seen.insert(parsed)
            nicks.append(parsed)
        }
        return nicks
    }

    /// Bağlantı metni boşsa yoldaki nick'e düşüyoruz: çaylak listesinde
    /// bağlantının içi kimi zaman ikon oluyor.
    private static func nick(from anchor: Element) throws -> String? {
        let text = try anchor.text().trimmed()
        if !text.isEmpty { return text }

        let href = try anchor.attr("href")
        let slug = href.dropFirst("/biri/".count).split(separator: "?", maxSplits: 1).first
        guard let slug, !slug.isEmpty else { return nil }
        return String(slug).removingPercentEncoding ?? String(slug)
    }
}
