import Foundation

/// Üst bardaki başlığı iki satıra bölüyor.
///
/// SwiftUI dar bir barda `lineLimit(2)` verilse bile metni küçültüp tek satıra
/// sıkıştırmayı tercih ediyor. Kırılma noktasını kendimiz koyuyoruz: ilk satır
/// en çok `limit` karakter, kelime ortasından bölünmüyor.
public enum TitleLayout {
    public static func twoLines(_ title: String, limit: Int = 35) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }

        let cut = trimmed.index(trimmed.startIndex, offsetBy: limit)
        let head = trimmed[trimmed.startIndex..<cut]

        // Sınıra kadarki son boşluktan bölüyoruz; boşluk yoksa tam sınırdan.
        guard let space = head.lastIndex(of: " ") else {
            return "\(head)\n\(trimmed[cut...])"
        }

        let first = trimmed[trimmed.startIndex..<space]
        let second = trimmed[trimmed.index(after: space)...]
        return "\(first)\n\(second)"
    }
}
