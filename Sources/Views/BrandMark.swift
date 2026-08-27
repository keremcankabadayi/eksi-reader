import SwiftUI

/// Uygulama işareti: ikondaki dört yatay çubuk.
///
/// Oranlar `tools/make-icon.mjs` içindeki `BARS` dizisinden alındı (16
/// birimlik ızgarada 10/8/9.5/5 genişlik, 1.4 kalınlık, 2.6 aralık) ve en
/// geniş çubuk 1.0 kabul edilip normalize edildi. İkonu değiştirirsen bu
/// sabitleri de güncelle, yoksa açılış ekranı ikona benzemez.
enum BrandMark {
    /// Çubuk genişlikleri, en geniş çubuğa oranla.
    static let widths: [CGFloat] = [1.0, 0.8, 0.95, 0.5]
    /// İkonda birinci ve dördüncü çubuk dolu renkte, ortadakiler sönük.
    static let opacities: [Double] = [1, 0.45, 0.45, 1]

    /// Çubuk kalınlığı ve iki çubuğun tepe aralığı, yine genişliğe oranla.
    static let thickness: CGFloat = 0.14
    static let pitch: CGFloat = 0.26

    static var count: Int { widths.count }

    /// İşaretin toplam yüksekliği (genişliğe oranla).
    static var heightRatio: CGFloat { pitch * CGFloat(count - 1) + thickness }
}

/// İşaretin çizimi. `width` en geniş çubuğun genişliği, yükseklik ondan
/// çıkıyor. Animasyonlu türevler çubuk başına opaklık/ölçek veriyor.
struct BrandMarkView: View {
    let width: CGFloat
    var tint: Color = Palette.brand
    /// Animasyonu tetikleyen durum; her çubuk buna kendi gecikmesiyle uyuyor.
    var phase: Bool = false
    var opacity: (Int) -> Double = { BrandMark.opacities[$0] }
    var scale: (Int) -> CGFloat = { _ in 1 }
    var animation: (Int) -> Animation? = { _ in nil }

    var body: some View {
        VStack(alignment: .leading, spacing: (BrandMark.pitch - BrandMark.thickness) * width) {
            ForEach(0..<BrandMark.count, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(tint)
                    .frame(
                        width: BrandMark.widths[index] * width,
                        height: BrandMark.thickness * width
                    )
                    .opacity(opacity(index))
                    // Sol kenar sabit: ikondaki gibi çubuklar aynı hizadan başlıyor.
                    .scaleEffect(x: scale(index), anchor: .leading)
                    .animation(animation(index), value: phase)
            }
        }
        .frame(width: width, height: BrandMark.heightRatio * width, alignment: .leading)
    }
}

/// Yükleme göstergesi: işaretin çubukları sırayla parlayıp sönüyor.
///
/// Sistem çarkıfeleğinin yerini alıyor; bütün bekleme anları aynı işareti
/// gösterdiği için uygulama tek parça duruyor.
struct BrandLoader: View {
    /// En geniş çubuğun genişliği. Satır içinde 14-18, ekran ortasında 44.
    var width: CGFloat = 44
    var tint: Color = Palette.brand

    @State private var animating = false

    var body: some View {
        BrandMarkView(
            width: width,
            tint: tint,
            phase: animating,
            opacity: { _ in animating ? 1 : 0.18 },
            animation: { index in
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                // Dalga: her çubuk bir öncekinden sonra başlıyor.
                .delay(Double(index) * 0.12)
            }
        )
        .onAppear { animating = true }
        .accessibilityLabel("yükleniyor")
    }
}

/// Ekran ortasında bekleme. Liste satırı olarak da kullanılabilsin diye
/// ayraçları kendisi gizliyor.
struct BrandLoadingView: View {
    var width: CGFloat = 44

    var body: some View {
        HStack {
            Spacer()
            BrandLoader(width: width)
            Spacer()
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.vertical, 40)
    }
}

#Preview {
    VStack(spacing: 40) {
        BrandMarkView(width: 96)
        BrandLoader()
        BrandLoader(width: 16)
    }
    .padding()
}
