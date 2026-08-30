import SwiftUI
import SukelaCore

/// Başlık listesindeki tek satır.
///
/// Zebra: Ekşi'nin kendi listesi gibi bir satır atlamalı zemin. Uzun
/// listelerde satırların birbirine karışmasını engelliyor.
struct TopicRow: View {
    let topic: Topic
    let isEven: Bool
    /// Okundu durumu. `nil` = bu akışta takip yok: nokta hiç çizilmiyor,
    /// satır solmuyor. Yalnız debe'de dolu geliyor; gündemde satır bir
    /// başlık, "okudum" demek anlamsız.
    var isRead: Bool?

    @AppStorage("entryFontSize") private var fontSize: Double = 16

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Okunmamışın solunda nokta: Slack'teki okunmamış kanal gibi,
            // listeye bakınca kaldığın yer belli oluyor. Takip kapalıyken
            // (gündem) nokta yok, satır da eskisi gibi.
            if let isRead {
                Circle()
                    .fill(isRead ? Color.clear : Palette.link)
                    .frame(width: 6, height: 6)
                    // Dairenin taban çizgisi yok; hizayı elle veriyoruz,
                    // yoksa metnin taban çizgisine oturup satırdan taşıyor.
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 1 }
            }

            Text(topic.title)
                .font(.system(size: fontSize))
                .foregroundStyle(isRead == true ? Palette.meta : Palette.text)
                .lineLimit(2)

            Spacer(minLength: 0)

            if !topic.entryCount.isEmpty {
                // Rozet değil, başlıkla aynı puntoda düz sayı.
                Text(topic.entryCount)
                    .font(.system(size: fontSize))
                    .monospacedDigit()
                    .foregroundStyle(Palette.sage)
            }
        }
        .padding(.vertical, 2)
    }

    /// Satır zemini; entry listesiyle aynı zebra kuralı.
    static func background(isEven: Bool) -> Color {
        Palette.row(isEven: isEven)
    }
}
