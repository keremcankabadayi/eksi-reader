import SwiftUI
import SukelaCore

/// Debe destesinde karar kaydırması — Slack'in "catch up" ekranındaki iş.
///
/// Elindeki yığını teker teker geçiyorsun ve her kart için tek bir karar
/// veriyorsun:
///
/// - **sağdan sola** (kartı sola at) → okundu
/// - **soldan sağa** (kartı sağa at) → okunmadı bırak
///
/// İki yön de sıradaki entry'ye geçiriyor; fark yalnızca okundu kaydında.
/// Hareket 3D: kart perspektifle dönüp elden çıkıyor, arkasında sıradaki
/// entry'nin kartı büyüyor. Kararın ne olacağı parmak kalkmadan damgada
/// yazıyor, yani ipucunu almak için hareketi tamamlamak gerekmiyor.
private struct CatchUpSwipe: ViewModifier {
    let enabled: Bool
    /// Arka kartta görünen sıradaki entry; deste bitiyorsa nil.
    let next: Topic?
    let nextIsRead: Bool
    /// `true` = okundu, `false` = okunmadı bırak.
    let onDecide: (Bool) -> Void

    /// Parmağın yatay yolu. Kaydırma bitince ya sıfıra ya ekran dışına gidiyor.
    @State private var dragX: CGFloat = 0
    /// Hareketin ekseni ilk noktalarda bir kez seçiliyor ve gesture bitene
    /// kadar korunuyor: kartlar dikey kaydırılırken deste dönmesin diye.
    @State private var locked: Axis?
    /// Karar animasyonu sürerken yeni kaydırma alınmıyor.
    @State private var deciding = false
    /// Oran hesabı için ekran genişliği; ilk çizimden önce makul bir sayı.
    @State private var width: CGFloat = 375

    /// -1 (tam sola) ile 1 (tam sağa) arası.
    private var progress: CGFloat {
        max(-1, min(1, dragX / width))
    }

    private var dragging: Bool {
        abs(dragX) > 0.5
    }

    /// Parmak şu an bırakılsa verilecek karar.
    private var decisionIsRead: Bool {
        dragX < 0
    }

    /// Kararın ne kadar belirginleştiği: 0 kapalı, 1 tamamen. Eşik yolun
    /// üçte biri; damga parmak daha yoldayken okunsun.
    private var reveal: CGFloat {
        min(1, abs(progress) / 0.33)
    }

    private var decisionColor: Color {
        decisionIsRead ? Palette.sage : Palette.link
    }

    func body(content: Content) -> some View {
        ZStack {
            // Sıradaki kart: öndeki döndükçe büyüyor.
            deckCard

            content
                // Kart gibi: kaydırırken köşeler yuvarlanıp gölge düşüyor.
                .clipShape(
                    RoundedRectangle(cornerRadius: dragging ? 24 : 0, style: .continuous)
                )
                .shadow(color: .black.opacity(dragging ? 0.45 : 0), radius: 22, x: 0, y: 10)
                // 3D: dönme + kaçış + hafif küçülme. Kart düz kaymıyor,
                // elden atılıyormuş gibi dönerek gidiyor.
                .rotation3DEffect(
                    .degrees(Double(progress) * -22),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .center,
                    anchorZ: 0,
                    perspective: 0.7
                )
                .rotationEffect(.degrees(Double(progress) * 3), anchor: .bottom)
                .offset(x: dragX * 0.65)
                .scaleEffect(1 - abs(progress) * 0.07)
                .overlay {
                    // Kararın rengi kartın üstüne yayılıyor: sola giderken
                    // adaçayı, sağa giderken amber.
                    decisionColor
                        .opacity(Double(reveal) * 0.14)
                        .allowsHitTesting(false)
                }
                .overlay(alignment: .top) { stamp }
        }
        .background(widthReader)
        // `simultaneous`: kartların kendi dikey kaydırması çalışmaya devam etsin.
        .simultaneousGesture(gesture)
    }

    /// Öndeki kartın arkasındaki entry. Deste bittiyse kapanış kartı.
    @ViewBuilder
    private var deckCard: some View {
        if enabled, dragging {
            VStack(spacing: 10) {
                if let next {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(nextIsRead ? Palette.meta : Palette.link)
                            .frame(width: 7, height: 7)
                        Text(nextIsRead ? "okundu" : "okunmadı")
                            .font(.caption2)
                            .foregroundStyle(Palette.meta)
                    }

                    Text(next.title)
                        .font(.headline)
                        .foregroundStyle(Palette.text)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)

                    Text("sıradaki")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.sage)
                } else {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Palette.sage)
                    Text("deste bitti")
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

    /// Kararı söyleyen damga. Parmak kalkmadan ne olacağı yazıyor.
    @ViewBuilder
    private var stamp: some View {
        if enabled, dragging {
            Label(
                decisionIsRead ? "okundu" : "okunmadı",
                systemImage: decisionIsRead ? "checkmark" : "envelope.badge"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(decisionColor))
            .rotationEffect(.degrees(decisionIsRead ? -6 : 6))
            .opacity(Double(reveal))
            .padding(.top, 14)
            .allowsHitTesting(false)
        }
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .local)
            .onChanged { drag in
                guard enabled, !deciding else { return }
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
                dragX = dx
            }
            .onEnded { drag in
                let horizontal = locked == .horizontal
                locked = nil
                guard enabled, !deciding, horizontal else {
                    settle()
                    return
                }

                let dx = drag.translation.width
                // Ya yeterince uzağa gitti ya da hızlı bir fiske attı.
                let far = abs(dx) > width * 0.28
                    || abs(drag.predictedEndTranslation.width) > width * 0.6
                guard far else {
                    settle()
                    return
                }
                commit(read: dx < 0)
            }
    }

    private func settle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            dragX = 0
        }
    }

    /// Karar verilen kart dönerek çıkıyor, sıradaki karşı kenardan giriyor.
    private func commit(read isRead: Bool) {
        deciding = true
        let exit = 0.16

        withAnimation(.easeIn(duration: exit)) {
            dragX = isRead ? -width : width
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + exit) {
            onDecide(isRead)
            // Sıradaki kart hep aynı yönden giriyor: deste hep ileri gidiyor.
            dragX = width * 0.5
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                dragX = 0
            }
            deciding = false
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
    /// Destedeki kartların ortak zemini: başlık kartı da entry kartı da
    /// aynı yüzeyde, zebra yok.
    func cardSurface() -> some View {
        background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Palette.surface)
        )
    }

    /// Debe destesinde okundu/okunmadı kaydırması. `enabled` kapalıyken
    /// hareket hiç dinlenmiyor: gündemden açılan başlıkta destenin karşılığı
    /// yok.
    func catchUpSwipe(
        enabled: Bool,
        next: Topic?,
        nextIsRead: Bool,
        onDecide: @escaping (Bool) -> Void
    ) -> some View {
        modifier(
            CatchUpSwipe(
                enabled: enabled,
                next: next,
                nextIsRead: nextIsRead,
                onDecide: onDecide
            )
        )
    }
}
