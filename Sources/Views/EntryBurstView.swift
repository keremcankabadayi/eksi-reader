import SwiftUI

/// Damganın anlattığı şey: oy verildi/geri alındı ya da favorilendi/çıkarıldı.
enum EntryBurstKind {
    case liked
    case unliked
    case favorited
    case unfavorited

    /// Geri alma damgaları kırık çiziliyor.
    var isRemoval: Bool { self == .unliked || self == .unfavorited }

    /// Kırığın nereden geçtiği ikonun kendi siluetine göre değişiyor:
    /// kalp geniş, damla tepede sivri.
    var crack: [CGPoint] { isFavorite ? Self.dropCrack : Self.heartCrack }

    private var isFavorite: Bool { self == .favorited || self == .unfavorited }

    /// Tepeden dibe zikzak: kesik düz olmasın.
    private static let heartCrack: [CGPoint] = [
        CGPoint(x: 8, y: 0),
        CGPoint(x: 9.6, y: 3.6),
        CGPoint(x: 6.6, y: 6.6),
        CGPoint(x: 9.4, y: 9.6),
        CGPoint(x: 7.2, y: 16),
    ]

    /// Damla tepede dar: zikzak orada da dar, yoksa kesik siluetin
    /// dışına taşıyor ve o yarıyı hiç kesmiyor.
    private static let dropCrack: [CGPoint] = [
        CGPoint(x: 8, y: 0),
        CGPoint(x: 9.2, y: 4),
        CGPoint(x: 6.9, y: 7.4),
        CGPoint(x: 9.3, y: 11.2),
        CGPoint(x: 7.3, y: 16),
    ]
}

/// Entry'nin üstünde bir kez oynayıp kaybolan geri bildirim damgası.
/// `id` her dokunuşta değiştiği için animasyon baştan başlıyor.
struct EntryBurst: Identifiable, Equatable {
    let id = UUID()
    let kind: EntryBurstKind
}

/// İkonu ortadan ikiye ayıran çatlak. 16x16'lık ikon kutusunda,
/// ikonun kendi koordinatlarıyla.
private struct CrackedHalf: Shape {
    let crack: [CGPoint]
    let leading: Bool

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let scale = side / 16
        let dx = rect.minX + (rect.width - side) / 2
        let dy = rect.minY + (rect.height - side) / 2
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: dx + x * scale, y: dy + y * scale)
        }

        // Çatlağın bir yanı ile kutunun kenarı arasında kalan alan.
        let edge: CGFloat = leading ? 0 : 16
        var path = Path()
        path.move(to: p(edge, 0))
        for point in crack {
            path.addLine(to: p(point.x, point.y))
        }
        path.addLine(to: p(edge, 16))
        path.closeSubpath()
        return path
    }
}

/// Çift dokunuşta ya da damla düğmesinde beliren damga: verilince dolu
/// ikon, geri alınınca ortadan ayrılıp düşen kırık ikon. İkisi de 3D
/// dönüşle geliyor.
struct EntryBurstView: View {
    let kind: EntryBurstKind

    @State private var entered = false
    @State private var split = false
    @State private var faded = false

    private static let size: CGFloat = 78

    private var tint: Color {
        kind.isRemoval ? Palette.meta : Palette.brand
    }

    var body: some View {
        content
            .shadow(color: tint.opacity(0.5), radius: entered ? 16 : 0, y: 6)
            .scaleEffect(entered ? 1 : 0.35)
            // Damga düz gelmiyor: yan yatık başlayıp okuyucuya dönüyor.
            .rotation3DEffect(
                .degrees(entered ? 0 : -75),
                axis: (x: 0.2, y: 1, z: 0),
                perspective: 0.7
            )
            .opacity(faded ? 0 : 1)
            .onAppear(perform: play)
    }

    @ViewBuilder
    private var content: some View {
        if kind.isRemoval {
            ZStack {
                half(leading: true)
                half(leading: false)
            }
        } else {
            icon
        }
    }

    /// Damganın ikonu: oy kalp, favori damla. İkisi de entry satırındaki
    /// dolu hâlin büyütülmüşü.
    @ViewBuilder
    private var icon: some View {
        switch kind {
        case .liked, .unliked:
            EksiHeartFill()
                .fill(tint)
                .frame(width: Self.size, height: Self.size)
        case .favorited, .unfavorited:
            EksiFlame()
                .fill(tint)
                .frame(width: Self.size, height: Self.size)
        }
    }

    /// Kırık ikonun bir yarısı: çatlaktan kesiliyor, sonra dışa devrilip
    /// aşağı kaçıyor.
    private func half(leading: Bool) -> some View {
        icon
            .clipShape(CrackedHalf(crack: kind.crack, leading: leading))
            .rotationEffect(
                .degrees(split ? (leading ? -17 : 17) : 0),
                anchor: leading ? .bottomTrailing : .bottomLeading
            )
            .offset(x: split ? (leading ? -8 : 8) : 0, y: split ? 7 : 0)
    }

    private func play() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.5)) {
            entered = true
        }
        if kind.isRemoval {
            withAnimation(.easeOut(duration: 0.45).delay(0.18)) {
                split = true
            }
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.45)) {
            faded = true
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        EntryBurstView(kind: .liked)
        EntryBurstView(kind: .unliked)
        EntryBurstView(kind: .favorited)
        EntryBurstView(kind: .unfavorited)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.base)
}
