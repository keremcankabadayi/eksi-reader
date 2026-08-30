import SwiftUI

/// Çift dokunuşun sonucu: oy verildi mi, geri mi alındı.
enum VoteBurstKind {
    case liked
    case unliked
}

/// Entry'nin üstünde bir kez oynayıp kaybolan geri bildirim damgası.
/// `id` her dokunuşta değiştiği için animasyon baştan başlıyor.
struct VoteBurst: Identifiable, Equatable {
    let id = UUID()
    let kind: VoteBurstKind
}

/// Kalbi ortadan ikiye ayıran çatlak. 16x16'lık ikon kutusunda,
/// `EksiHeartFill` ile aynı koordinatlarda.
private struct CrackedHalf: Shape {
    let leading: Bool

    /// Tepeden dibe zikzak: kırık kalbin kesiği düz olmasın.
    private static let crack: [CGPoint] = [
        CGPoint(x: 8, y: 0),
        CGPoint(x: 9.6, y: 3.6),
        CGPoint(x: 6.6, y: 6.6),
        CGPoint(x: 9.4, y: 9.6),
        CGPoint(x: 7.2, y: 16),
    ]

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
        for point in Self.crack {
            path.addLine(to: p(point.x, point.y))
        }
        path.addLine(to: p(edge, 16))
        path.closeSubpath()
        return path
    }
}

/// Çift dokunuşta beliren damga: oy verilince dolu kalp, geri alınınca
/// ortadan ayrılıp düşen kırık kalp. İkisi de 3D dönüşle geliyor.
struct VoteBurstView: View {
    let kind: VoteBurstKind

    @State private var entered = false
    @State private var split = false
    @State private var faded = false

    private static let size: CGFloat = 78

    private var tint: Color {
        kind == .liked ? Palette.brand : Palette.meta
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
        switch kind {
        case .liked:
            EksiHeartFill()
                .fill(tint)
                .frame(width: Self.size, height: Self.size)
        case .unliked:
            ZStack {
                half(leading: true)
                half(leading: false)
            }
        }
    }

    /// Kırık kalbin bir yarısı: çatlaktan kesiliyor, sonra dışa devrilip
    /// aşağı kaçıyor.
    private func half(leading: Bool) -> some View {
        EksiHeartFill()
            .fill(tint)
            .frame(width: Self.size, height: Self.size)
            .clipShape(CrackedHalf(leading: leading))
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
        if kind == .unliked {
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
    VStack(spacing: 60) {
        VoteBurstView(kind: .liked)
        VoteBurstView(kind: .unliked)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Palette.base)
}
