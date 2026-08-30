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
    /// Favori sayısına dokunuldu: listeyi başlık ekranı açıyor.
    let showFavorites: () -> Void

    @EnvironmentObject private var auth: AuthSession
    @EnvironmentObject private var votes: VoteService

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
            // Tarih meta gri, nick adaçayı: ikisi aynı renk olunca imza
            // tek blok gibi okunuyordu.
            VStack(alignment: .trailing, spacing: 0) {
                Text(entry.date)
                    .foregroundStyle(Palette.meta)
                Text(entry.author.nick)
                    .foregroundStyle(Palette.nick)
            }
            .font(.caption2)
            .multilineTextAlignment(.trailing)

            AvatarView(url: entry.author.avatarURL)
        }
    }

    private var actions: some View {
        HStack(spacing: 22) {
            Spacer(minLength: 0)

            if entry.favoriteCount > 0 {
                // Dokununca favorileyenler açılıyor, Ekşi'deki gibi.
                Button(action: showFavorites) {
                    // Label ikon ile sayı arasına geniş bir boşluk koyuyor;
                    // ikiliyi kendimiz diziyoruz.
                    HStack(spacing: 3) {
                        EksiFlame()
                            .frame(width: 11, height: 11)
                        Text("\(entry.favoriteCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(Palette.meta)
                }
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

            // Oy vermek Ekşi'de giriş istiyor: girişsizken ikonlar duruyor
            // ama sönük ve pasif. Ekşi'deki gibi ikisi bitişik, aralarında
            // ince ayraç (`eksico-like-seperator`: 1x16, rx 0.5).
            HStack(spacing: 9) {
                voteButton(.up)
                Capsule()
                    .frame(width: 1, height: 14)
                    .foregroundStyle(Palette.link.opacity(0.3))
                voteButton(.down)
            }

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

    /// Aynı yöne ikinci kez basmak oyu geri alıyor; rengi `VoteService`
    /// söylüyor, istek dönene kadar düğme kapalı.
    private func voteButton(_ direction: VoteDirection) -> some View {
        let current = votes.direction(for: entry)
        let busy = votes.isPending(entry.id)

        return Button {
            Task { await votes.toggle(entry: entry, direction: direction) }
        } label: {
            voteIcon(direction, filled: current == direction)
                .frame(width: 16, height: 16)
        }
        .disabled(!auth.isLoggedIn || busy)
        .foregroundStyle(voteTint(direction, current: current, busy: busy))
    }

    /// Ekşi'nin kendi ikonları: artı oy kalp, eksi oy içi çizgili kutu.
    /// Oy verilince ikisi de dolu hâline geçiyor.
    @ViewBuilder
    private func voteIcon(_ direction: VoteDirection, filled: Bool) -> some View {
        switch (direction, filled) {
        case (.up, false):
            EksiHeart()
        case (.up, true):
            EksiHeartFill()
        case (.down, false):
            // Kutu ve içindeki çizgi kapalı alan değil, çizgi: stroke gerekiyor.
            EksiDislike()
                .stroke(style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        case (.down, true):
            EksiDislikeFill()
        }
    }

    private func voteTint(_ direction: VoteDirection, current: VoteDirection?, busy: Bool) -> Color {
        guard auth.isLoggedIn else { return Palette.link.opacity(0.3) }
        if current == direction { return Palette.brand }
        return Palette.link.opacity(busy ? 0.4 : 1)
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
