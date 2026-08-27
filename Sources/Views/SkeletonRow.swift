import SwiftUI

/// Yükleme iskeleti: gelecek başlıkların yerini tutan gri bloklar.
///
/// Tek bir çarkıfelek yerine listenin şeklini gösteriyoruz; ekran boş
/// kalmadığı için aynı süre daha kısa hissettiriyor.
struct SkeletonRow: View {
    let index: Int

    @State private var dim = false

    /// Satırlar farklı uzunlukta olsun diye sabit bir desen; rastgele
    /// olsaydı her çizimde değişip titrerdi.
    private static let widths: [CGFloat] = [0.82, 0.55, 0.7, 0.45, 0.9, 0.62]

    private var width: CGFloat { Self.widths[index % Self.widths.count] }

    var body: some View {
        HStack(spacing: 12) {
            GeometryReader { geometry in
                block.frame(width: geometry.size.width * width)
            }
            .frame(height: 14)

            block.frame(width: 26, height: 14)
        }
        .padding(.vertical, 9)
        .opacity(dim ? 0.45 : 1)
        .animation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: dim
        )
        .onAppear { dim = true }
    }

    private var block: some View {
        RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(Palette.meta.opacity(0.35))
    }
}

/// Liste boşken gösterilen iskelet satırları.
struct SkeletonList: View {
    var count = 12

    var body: some View {
        ForEach(0..<count, id: \.self) { index in
            SkeletonRow(index: index)
                .listRowBackground(Palette.row(isEven: index % 2 == 0))
                .listRowSeparator(.hidden)
        }
    }
}
