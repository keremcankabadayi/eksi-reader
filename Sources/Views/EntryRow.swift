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
    @EnvironmentObject private var favorites: FavoriteService

    /// Çift dokunuşta oynayan damga; kendi kendine sönüyor.
    @State private var burst: VoteBurst?

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
        // Instagram'daki gibi: gövdeye çift dokunmak artı oy veriyor,
        // ikinci çift dokunuş geri alıyor. Tek dokunuş hâlâ bağlantıları
        // açıyor, `count: 2` onun önüne geçmiyor.
        .onTapGesture(count: 2, perform: doubleTapVote)
        .overlay {
            if let burst {
                VoteBurstView(kind: burst.kind)
                    .id(burst.id)
                    .allowsHitTesting(false)
            }
        }
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
            .font(.system(size: signatureSize))
            .multilineTextAlignment(.trailing)

            AvatarView(url: entry.author.avatarURL, size: avatarSize)
        }
    }

    /// İmza ve avatar gövdeyle birlikte büyüsün: ayarlardaki punto yalnız
    /// gövdeye gidince tarih, nick ve avatar orantısız küçük kalıyordu.
    /// Oranlar varsayılan 16 puntoda bugünkü boyutları veriyor
    /// (caption2 ≈ 11 punto, avatar 26 punto).
    private var signatureSize: CGFloat { CGFloat(fontSize) * 0.69 }

    private var avatarSize: CGFloat { CGFloat(fontSize) * 1.625 }

    private var actions: some View {
        HStack(spacing: 22) {
            Spacer(minLength: 0)

            // Ekşi'deki ayrımın aynısı: damlanın kendisi favoriye ekleyip
            // çıkarıyor, yanındaki sayı favorileyenleri açıyor.
            HStack(spacing: 4) {
                favoriteButton

                if favoriteState.count > 0 {
                    Button(action: showFavorites) {
                        Text("\(favoriteState.count)")
                            .font(.caption)
                            // İmzadaki nick ile aynı renk.
                            .foregroundStyle(Palette.nick)
                            .monospacedDigit()
                            // Sayı tek karakter olduğunda dokunulacak alan
                            // fazla küçülüyor.
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
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

    private var favoriteState: FavoriteService.State {
        favorites.state(for: entry)
    }

    /// Favori damlası: boşken favoride değil, doluyken favoride. Oy gibi
    /// giriş istiyor, girişsizken sönük ve pasif.
    private var favoriteButton: some View {
        let state = favoriteState
        let busy = favorites.isPending(entry.id)

        return Button {
            UIImpactFeedbackGenerator(style: state.isFavorite ? .rigid : .soft)
                .impactOccurred()
            Task { await favorites.toggle(entry: entry) }
        } label: {
            Group {
                if state.isFavorite {
                    EksiFlame()
                } else {
                    // Damla kapalı alan; boş hâli kendi konturuyla çiziliyor.
                    EksiFlame()
                        .stroke(style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                }
            }
            .frame(width: 13, height: 13)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .disabled(!auth.isLoggedIn || busy)
        .foregroundStyle(favoriteTint(state.isFavorite, busy: busy))
        .accessibilityLabel(state.isFavorite ? "favorilerden çıkar" : "favorilere ekle")
    }

    private func favoriteTint(_ isFavorite: Bool, busy: Bool) -> Color {
        guard auth.isLoggedIn else { return Palette.link.opacity(0.3) }
        if isFavorite { return Palette.brand }
        return Palette.link.opacity(busy ? 0.4 : 1)
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

    /// Çift dokunuş = artı oy düğmesi. Oy zaten artıysa geri alıyor,
    /// damga da ona göre: dolu kalp ya da kırık kalp.
    private func doubleTapVote() {
        // Girişsizken ya da istek uçarken damga yok; uyarıyı servis basıyor.
        guard auth.isLoggedIn, !votes.isPending(entry.id) else {
            Task { await votes.toggle(entry: entry, direction: .up) }
            return
        }

        let removing = votes.direction(for: entry) == .up
        let mark = VoteBurst(kind: removing ? .unliked : .liked)
        burst = mark

        UIImpactFeedbackGenerator(style: removing ? .rigid : .soft).impactOccurred()

        Task { await votes.toggle(entry: entry, direction: .up) }
        Task {
            try? await Task.sleep(nanoseconds: 850_000_000)
            // Bu arada yeniden dokunulduysa yeni damga oynuyor, ona karışma.
            if burst?.id == mark.id { burst = nil }
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
    /// Entry puntosuyla birlikte büyüyor.
    let size: CGFloat

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
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(.secondary)
            )
    }
}
