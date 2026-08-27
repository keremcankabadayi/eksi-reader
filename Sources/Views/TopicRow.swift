import SwiftUI
import SukelaCore

/// Başlık listesindeki tek satır.
///
/// Zebra: Ekşi'nin kendi listesi gibi bir satır atlamalı zemin. Uzun
/// listelerde satırların birbirine karışmasını engelliyor.
struct TopicRow: View {
    let topic: Topic
    let isEven: Bool

    @AppStorage("entryFontSize") private var fontSize: Double = 16

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(topic.title)
                .font(.system(size: fontSize))
                .foregroundStyle(Palette.text)
                .lineLimit(2)

            Spacer(minLength: 0)

            if !topic.entryCount.isEmpty {
                // Rozet değil, başlıkla aynı puntoda düz sayı.
                Text(topic.entryCount)
                    .font(.system(size: fontSize))
                    .monospacedDigit()
                    .foregroundStyle(Palette.link)
            }
        }
        .padding(.vertical, 2)
    }

    /// Satır zemini; entry listesiyle aynı zebra kuralı.
    static func background(isEven: Bool) -> Color {
        Palette.row(isEven: isEven)
    }
}
