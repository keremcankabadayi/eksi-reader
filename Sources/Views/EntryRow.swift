import SwiftUI
import UIKit
import SukelaCore

/// Listedeki tek entry. Düzen Şükela Reader'dan: gövde, sağda tarih ve nick,
/// yanında avatar, altında sağa hizalı işlem ikonları.
struct EntryRow: View {
    let rendered: RenderedEntry
    let fontSize: Double
    let openInApp: (String, String) -> Void
    let openPopup: (PopupLink) -> Void

    private var entry: Entry { rendered.entry }

    private var permalink: URL? {
        EntryLink.entry(id: entry.id).url
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            EntryBodyView(
                rendered: rendered,
                fontSize: fontSize,
                openInApp: openInApp,
                openPopup: openPopup
            )

            signature

            actions
        }
        .padding(.vertical, 4)
    }

    private var signature: some View {
        HStack(alignment: .center, spacing: 8) {
            Spacer(minLength: 0)

            // Tarih ve nick sıkışık duruyor: entry gövdesi ile alttaki
            // ikon sırası arasında ince bir şerit kalsın.
            VStack(alignment: .trailing, spacing: 0) {
                Text(entry.date)
                Text(entry.author.nick)
            }
            .font(.caption2)
            .foregroundStyle(Palette.sage)
            .multilineTextAlignment(.trailing)

            AvatarView(url: entry.author.avatarURL)
        }
    }

    private var actions: some View {
        HStack(spacing: 22) {
            Spacer(minLength: 0)

            if entry.favoriteCount > 0 {
                // Label kalp ile sayı arasına geniş bir boşluk koyuyor;
                // ikiliyi kendimiz diziyoruz.
                HStack(spacing: 3) {
                    Image(systemName: "heart")
                    Text("\(entry.favoriteCount)")
                }
                .font(.caption)
                .foregroundStyle(Palette.meta)
            }

            Menu {
                Button {
                    UIPasteboard.general.string = rendered.plain
                } label: {
                    Label("entry'yi kopyala", systemImage: "doc.on.doc")
                }

                if let permalink {
                    Button {
                        UIPasteboard.general.string = permalink.absoluteString
                    } label: {
                        Label("bağlantıyı kopyala", systemImage: "link")
                    }

                    Button {
                        openPopup(PopupLink(url: permalink, label: "entry \(entry.id)"))
                    } label: {
                        Label("tarayıcıda aç", systemImage: "safari")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
            }

            // Oy vermek Ekşi'de giriş istiyor, bu uygulamada giriş yok.
            // Düzen bozulmasın diye oklar duruyor ama pasif.
            Image(systemName: "arrow.up")
                .foregroundStyle(Palette.link.opacity(0.3))
            Image(systemName: "arrow.down")
                .foregroundStyle(Palette.link.opacity(0.3))

            if let permalink {
                ShareLink(item: permalink) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .font(.system(size: 15))
        .foregroundStyle(Palette.link)
        .buttonStyle(.plain)
    }
}

/// Yazar avatarı. Yoksa ya da yüklenemezse yerine daire çiziliyor.
private struct AvatarView: View {
    let url: String?

    private static let size: CGFloat = 26

    var body: some View {
        Group {
            if let url, let parsed = URL(string: url) {
                AsyncImage(url: parsed) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: Self.size, height: Self.size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: Self.size * 0.5))
                    .foregroundStyle(.secondary)
            )
    }
}
