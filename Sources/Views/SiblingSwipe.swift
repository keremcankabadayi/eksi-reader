import SwiftUI
import SukelaCore

/// Debe'de komşu entry'ye geçişin 3D deste hissi.
///
/// Slack'in "catch up" ekranındaki mantık: elindeki yığını teker teker
/// geçiyorsun, sola attığın okunmuş sayılıp gidiyor, sağa attığın geri
/// getiriyor. Buradaki karşılığı:
///
/// - **sola kaydır** → sıradaki entry (okundu işareti zaten açılışta düşüyor)
/// - **sağa kaydır** → bir önceki entry
///
/// Görsel taraf ipucu vermek için var: parmak değdiği anda sayfa bir kart
/// gibi kenarlarından ayrılıp perspektifle dönüyor, arkasında sıradaki
/// entry'nin kartı büyüyerek beliriyor. Yani hareketi keşfetmek için
/// tamamlamak gerekmiyor, 20 piksel yetiyor.
private struct SiblingSwipe: ViewModifier {
    let enabled: Bool
    let previous: Topic?
    let next: Topic?
    /// Kaçıncı entry / toplam. Üstteki ilerleme şeridi bunu çiziyor.
    let position: Int?
    let total: Int
    /// Arka kartta "okunmadı" noktası için.
    let isRead: (Topic) -> Bool
    let onSwitch: (Topic) -> Void

    /// Parmağın yatay yolu. Kaydırma bitince ya sıfıra ya ekran dışına gidiyor.
    @State private var dragX: CGFloat = 0
    /// Hareketin ekseni ilk noktalarda bir kez seçiliyor ve gesture bitene
    /// kadar korunuyor: liste dikey kaydırılırken sayfa dönmesin diye.
    @State private var locked: Axis?
    /// Geçiş animasyonu sürerken yeni kaydırma alınmıyor.
    @State private var switching = false
    /// Oran hesabı için ekran genişliği; ilk çizimden önce makul bir sayı.
    @State private var width: CGFloat = 375

    /// -1 (tam sola) ile 1 (tam sağa) arası.
    private var progress: CGFloat {
        max(-1, min(1, dragX / width))
    }

    private var dragging: Bool {
        abs(dragX) > 0.5
    }

    /// Kaydırmanın gittiği entry; yön boşsa nil.
    private var target: Topic? {
        dragX == 0 ? nil : (dragX < 0 ? next : previous)
    }

    /// Kartın ne kadar açıldığı: 0 kapalı, 1 tamamen. Eşik yolun üçte biri;
    /// ipucu parmak daha yoldayken tam görünsün.
    private var reveal: CGFloat {
        min(1, abs(progress) / 0.33)
    }

    func body(content: Content) -> some View {
        ZStack {
            // Arkadaki entry, öndeki kart döndükçe büyüyor.
            deckCard

            content
                // Kart gibi: kaydırırken köşeler yuvarlanıp gölge düşüyor,
                // parmak kalkınca ekran yine ekran oluyor.
                .clipShape(
                    RoundedRectangle(cornerRadius: dragging ? 24 : 0, style: .continuous)
                )
                .shadow(color: .black.opacity(dragging ? 0.45 : 0), radius: 22, x: 0, y: 10)
                // 3D: dönme + kaçış + hafif küçülme birlikte. Sayfa düz
                // kaymıyor, kapı gibi açılıyor.
                .rotation3DEffect(
                    .degrees(Double(progress) * -22),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .center,
                    anchorZ: 0,
                    perspective: 0.7
                )
                // Deste hissi için ufak bir eğim; kart elden atılıyormuş gibi.
                .rotationEffect(.degrees(Double(progress) * 3), anchor: .bottom)
                .offset(x: dragX * 0.6)
                .scaleEffect(1 - abs(progress) * 0.07)
                .overlay {
                    // Uzaklaşan yüz koyulaşıyor; derinlik yalnız
                    // perspektiften gelmiyor.
                    Color.black
                        .opacity(Double(abs(progress)) * 0.22)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .top) { stamp }
        }
        .overlay(alignment: .top) { progressBar }
        .background(widthReader)
        // `simultaneous`: listenin kendi dikey kaydırması çalışmaya devam etsin.
        .simultaneousGesture(gesture)
    }

    /// Öndeki kartın arkasındaki entry. Kaydırma yönüne göre önceki ya da
    /// sonraki; o yönde entry yoksa "listenin sonu" kartı.
    @ViewBuilder
    private var deckCard: some View {
        if enabled, dragging {
            VStack(spacing: 10) {
                if let target {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isRead(target) ? Palette.meta : Palette.link)
                            .frame(width: 7, height: 7)
                        Text(isRead(target) ? "okundu" : "okunmadı")
                            .font(.caption2)
                            .foregroundStyle(Palette.meta)
                    }

                    Text(target.title)
                        .font(.headline)
                        .foregroundStyle(Palette.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)

                    Label(
                        dragX < 0 ? "sıradaki" : "önceki",
                        systemImage: dragX < 0 ? "arrow.left" : "arrow.right"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.sage)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Palette.meta)
                    Text(dragX < 0 ? "listenin sonu" : "listenin başı")
                        .font(.callout)
                        .foregroundStyle(Palette.meta)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Palette.surface)
            )
            // Arka kart öne doğru geliyor: küçükten normale, soluktan net'e.
            .scaleEffect(0.82 + 0.18 * reveal)
            .opacity(Double(reveal))
            .rotation3DEffect(
                .degrees(Double(progress) * 10),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.7
            )
            .allowsHitTesting(false)
        }
    }

    /// Kaydırma yönünü söyleyen damga: Slack'te olduğu gibi hareket
    /// tamamlanmadan ne olacağı yazıyor.
    @ViewBuilder
    private var stamp: some View {
        if enabled, dragging, target != nil {
            Text(dragX < 0 ? "sıradaki entry" : "önceki entry")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Palette.link))
                .rotationEffect(.degrees(dragX < 0 ? -6 : 6))
                .opacity(Double(reveal))
                .padding(.top, 12)
                .allowsHitTesting(false)
        }
    }

    /// Üstteki ince şerit: destede nerede olduğun. Kaydırmayı beklemeden
    /// görünüyor, "burada bir sıra var" demenin en ucuz yolu.
    @ViewBuilder
    private var progressBar: some View {
        if enabled, let position, total > 1 {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.meta.opacity(0.25))
                    Capsule()
                        .fill(Palette.link)
                        .frame(width: geo.size.width * CGFloat(position) / CGFloat(total))
                }
            }
            .frame(height: 2)
            .allowsHitTesting(false)
        }
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { drag in
                guard enabled, !switching else { return }
                let dx = drag.translation.width
                let dy = drag.translation.height

                if locked == nil {
                    // Sol kenardan başlayan sağa kaydırma sistemin geri
                    // hareketi; ona karışmıyoruz.
                    if drag.startLocation.x < 40, dx > 0 {
                        locked = .vertical
                        return
                    }
                    if abs(dx) > 14, abs(dx) > abs(dy) * 1.5 {
                        locked = .horizontal
                    } else if abs(dy) > 14 {
                        locked = .vertical
                    }
                }
                guard locked == .horizontal else { return }

                // O yönde entry yoksa yol dörtte bire iniyor: hareket
                // hissediliyor ama sonuçlanmayacağı da belli oluyor.
                dragX = (dx < 0 ? next : previous) == nil ? dx / 4 : dx
            }
            .onEnded { drag in
                let horizontal = locked == .horizontal
                locked = nil
                guard enabled, !switching, horizontal else {
                    settle()
                    return
                }

                let dx = drag.translation.width
                // Ya yeterince uzağa gitti ya da hızlı bir fiske attı.
                let far = abs(dx) > width * 0.28
                    || abs(drag.predictedEndTranslation.width) > width * 0.6
                guard far, let destination = dx < 0 ? next : previous else {
                    settle()
                    return
                }
                commit(to: destination, goingLeft: dx < 0)
            }
    }

    private func settle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            dragX = 0
        }
    }

    /// Eski kart çıktığı yönden dönerek gidiyor, yeni kart karşı kenardan
    /// giriyor. İçerik yüklemesi `onSwitch` ile başlıyor.
    private func commit(to destination: Topic, goingLeft: Bool) {
        switching = true
        let exit = 0.16

        withAnimation(.easeIn(duration: exit)) {
            dragX = goingLeft ? -width : width
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + exit) {
            onSwitch(destination)
            dragX = goingLeft ? width * 0.5 : -width * 0.5
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                dragX = 0
            }
            switching = false
        }
    }

    private var widthReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { width = max(geo.size.width, 1) }
                .onChange(of: geo.size.width) { width = max($0, 1) }
        }
    }
}

extension View {
    /// Debe'de komşu entry'ler arası 3D deste kaydırması. `enabled`
    /// kapalıyken hareket hiç dinlenmiyor: başlık listesinden açılan normal
    /// başlıkta yatay kaydırmanın karşılığı yok.
    func siblingSwipe(
        enabled: Bool,
        previous: Topic?,
        next: Topic?,
        position: Int?,
        total: Int,
        isRead: @escaping (Topic) -> Bool,
        onSwitch: @escaping (Topic) -> Void
    ) -> some View {
        modifier(
            SiblingSwipe(
                enabled: enabled,
                previous: previous,
                next: next,
                position: position,
                total: total,
                isRead: isRead,
                onSwitch: onSwitch
            )
        )
    }
}
