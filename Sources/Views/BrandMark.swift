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
    /// En geniş çubuğun genişliği. Satır içinde 14-18, ekran ortasında 56.
    var width: CGFloat = 44
    var tint: Color = Palette.brand
    /// Ekran ortasındaki büyük gösterge kendi ekseninde dönüyor: çubuklar
    /// öne gelirken genişliyor, arkaya giderken daralıyor. Satır içi küçük
    /// kullanımlarda dönüş göz yorduğu için kapalı.
    var spins = false

    @State private var animating = false
    @State private var spin: Double = 0

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
        // Zeminden yükselmiş dursun.
        .shadow(
            color: .black.opacity(spins ? 0.3 : 0),
            radius: width * 0.14,
            y: width * 0.1
        )
        // Hafif yatık duruş, üstüne kendi ekseninde dönüş.
        .rotation3DEffect(
            .degrees(spins ? 18 : 0),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.6
        )
        .rotation3DEffect(
            .degrees(spin),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.75
        )
        .onAppear {
            animating = true
            guard spins else { return }
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) {
                spin = 360
            }
        }
        .accessibilityLabel("yükleniyor")
    }
}

/// Ekranın tam ortasında bekleme. Liste satırı değil: içeriğin üstüne
/// `overlay` olarak konuluyor, gösterge ortada duruyor.
struct BrandLoadingView: View {
    var width: CGFloat = 56

    var body: some View {
        BrandLoader(width: width, spins: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
