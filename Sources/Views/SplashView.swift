import SwiftUI

/// Açılış ekranı.
///
/// `UILaunchScreen` boş: sistem uygulamayı düz bir zeminle açıyor. Bu ekran
/// onun üstüne aynı zeminle biniyor, ikondaki çubukları sırayla çizip
/// sönüyor; böylece ikondan uygulamaya kesintisiz bir geçiş oluyor.
///
/// Bir şeyi beklemiyor, yalnızca gösteriliyor: Cloudflare ısınması arka
/// planda sürüyor, açılışı ona bağlarsak ağ yavaşken uygulama kilitli durur.
struct SplashView: View {
    /// Çubuklar çizildikten sonra ekranın kapanması.
    let finish: () -> Void

    @State private var drawn = false
    @State private var titleShown = false

    /// Çubuk çizimi + son çubuğun gecikmesi + okuma payı.
    private static let dwell: UInt64 = 1_050_000_000

    var body: some View {
        ZStack {
            Palette.base
                .ignoresSafeArea()

            VStack(spacing: 26) {
                BrandMarkView(
                    width: 108,
                    phase: drawn,
                    scale: { _ in drawn ? 1 : 0 },
                    animation: { index in
                        .spring(response: 0.5, dampingFraction: 0.8)
                        // Çubuklar yukarıdan aşağı sırayla açılıyor.
                        .delay(Double(index) * 0.09)
                    }
                )

                Text("şükela lite")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Palette.meta)
                    .opacity(titleShown ? 1 : 0)
                    .animation(.easeOut(duration: 0.35), value: titleShown)
            }
        }
        .task {
            drawn = true
            titleShown = true
            try? await Task.sleep(nanoseconds: Self.dwell)
            finish()
        }
    }
}

#Preview {
    SplashView {}
}
