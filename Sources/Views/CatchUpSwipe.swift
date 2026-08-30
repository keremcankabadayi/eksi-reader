import SwiftUI
import SukelaCore

/// Debe destesinde karar kaydırması — Slack'in "catch up" ekranındaki iş.
///
/// Elindeki desteyi teker teker geçiyorsun, her kart için tek karar:
///
/// - **sağdan sola** (kartı sola at) → okundu, kart yeşile boyanıyor
/// - **soldan sağa** (kartı sağa at) → okunmadı bırak, kart maviye boyanıyor
///
/// İki yön de sıradaki entry'ye geçiriyor, fark yalnızca okundu kaydında.
/// Slack'in mekaniği: karara ait renk parmağın gittiği yol kadar koyulaşıyor,
/// eşiğin altında bırakılan kart yerine yaslanıyor, karta dokunulduğu anda
/// kart hafifçe küçülüp "elimde" hissi veriyor.
///
/// Destenin arkadaki kartlarını bu modifier çizmiyor: onlar ekranın kendi
/// düzeninde (`TopicDetailView.deck`) duruyor, öndeki kart çekilince
/// arkadaki kendiliğinden görünüyor.
private struct CatchUpSwipe: ViewModifier {
    let enabled: Bool
    /// Kartın köşe yarıçapı; boyama ve kenar çizgisi kartla aynı biçimde
    /// dursun diye dışarıdan geliyor.
    let cornerRadius: CGFloat
    /// `true` = okundu, `false` = okunmadı bırak.
    let onDecide: (Bool) -> Void

    /// Parmağın yatay yolu. Kaydırma bitince ya sıfıra ya ekran dışına gidiyor.
    @State private var dragX: CGFloat = 0
    /// Hareketin ekseni ilk noktalarda bir kez seçiliyor ve gesture bitene
    /// kadar korunuyor: kart içi dikey kaydırılırken deste dönmesin diye.
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
    /// üçte biri; renk ve damga parmak daha yoldayken okunsun.
    private var reveal: CGFloat {
        min(1, abs(progress) / 0.33)
    }

    private var decisionColor: Color {
        decisionIsRead ? Palette.decisionRead : Palette.decisionUnread
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            // Karar rengi kartın yüzeyine yayılıyor; kartla aynı biçimde
            // kesiliyor ki köşelerden taşmasın.
            .overlay {
                shape
                    .fill(decisionColor)
                    .opacity(Double(reveal) * 0.28)
                    .allowsHitTesting(false)
            }
            .overlay {
                shape
                    .strokeBorder(decisionColor, lineWidth: 2)
                    .opacity(Double(reveal))
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .top) { stamp }
            .clipShape(shape)
            .shadow(color: .black.opacity(dragging ? 0.5 : 0.25), radius: 18, x: 0, y: 8)
            // 3D: kart perspektifle dönüp elden çıkıyor.
            .rotation3DEffect(
                .degrees(Double(progress) * -20),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.7
            )
            .rotationEffect(.degrees(Double(progress) * 3), anchor: .bottom)
            .offset(x: dragX * 0.7)
            // Dokunulan kart hafifçe küçülüyor: Slack'te de kart "eline
            // geliyor", sonra karar verilince destesinden çıkıyor.
            .scaleEffect(dragging ? 0.97 - abs(progress) * 0.05 : 1)
            .animation(.easeOut(duration: 0.15), value: dragging)
            .background(widthReader)
            // `simultaneous`: kartın içindeki dikey kaydırma çalışmaya devam etsin.
            .simultaneousGesture(gesture)
    }

    /// Kararı söyleyen damga. Parmak kalkmadan ne olacağı yazıyor.
    @ViewBuilder
    private var stamp: some View {
        if enabled, dragging {
            Label(
                decisionIsRead ? "okundu" : "okunmadı",
                systemImage: decisionIsRead ? "checkmark.circle.fill" : "envelope.fill"
            )
            .font(.subheadline.weight(.bold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(decisionColor))
            .rotationEffect(.degrees(decisionIsRead ? -6 : 6))
            .opacity(Double(reveal))
            .padding(.top, 16)
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
                // Ya yeterince uzağa gitti ya da hızlı bir fiske attı;
                // ikisi de değilse kart yerine yaslanıyor.
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

    /// Karar verilen kart dönerek çıkıyor, altındaki kart öne geliyor.
    private func commit(read isRead: Bool) {
        deciding = true
        let exit = 0.18

        withAnimation(.easeIn(duration: exit)) {
            dragX = isRead ? -width * 1.2 : width * 1.2
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + exit) {
            onDecide(isRead)
            // Yeni kart destenin altından geldi; yerinde başlıyor.
            dragX = 0
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
    /// Destedeki kartların ortak zemini. Başlık kartı da entry kartı da
    /// aynı yüzeyde; zebra yalnız gündemin liste düzeninde kaldı.
    func cardSurface(cornerRadius: CGFloat = 22) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Palette.surface)
        )
    }

    /// Debe destesinde okundu/okunmadı kaydırması. `enabled` kapalıyken
    /// hareket hiç dinlenmiyor: gündemden açılan başlıkta destenin karşılığı
    /// yok.
    func catchUpSwipe(
        enabled: Bool,
        cornerRadius: CGFloat = 22,
        onDecide: @escaping (Bool) -> Void
    ) -> some View {
        modifier(
            CatchUpSwipe(
                enabled: enabled,
                cornerRadius: cornerRadius,
                onDecide: onDecide
            )
        )
    }
}
