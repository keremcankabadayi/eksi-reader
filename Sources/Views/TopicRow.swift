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
                .lineLimit(2)

            Spacer(minLength: 0)

            if !topic.entryCount.isEmpty {
                // Rozet değil, başlıkla aynı puntoda düz sayı.
                Text(topic.entryCount)
                    .font(.system(size: fontSize))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 2)
    }

    /// Satır zemini. Tema renklerine dokunmadan, mevcut zeminin üstüne
    /// çok hafif bir kontrast koyuyor; açık ve koyu temada da çalışıyor.
    static func background(isEven: Bool) -> Color {
        isEven ? Color.clear : Color.primary.opacity(0.04)
    }
}
