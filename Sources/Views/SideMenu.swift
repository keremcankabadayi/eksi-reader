import SwiftUI
import UIKit

/// Sağdan açılan menü. Üst bardaki ikon ya da sağ kenardan içeri kaydırma
/// açıyor; karartmaya dokunmak ya da sağa sürüklemek kapatıyor.
///
/// Sekme çubuğunun da üstünü kaplaması gerektiği için `RootView`'un en
/// dışına, TabView'i sarmalayarak konuluyor.
struct DrawerContainer<Content: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder var content: () -> Content

    /// Parmak menüyü sürüklerken kapalı/açık konuma eklenen kayma;
    /// bırakılınca sıfırlanıyor, karar `isOpen`'a yazılıyor.
    @State private var drag: CGFloat = 0

    /// Ekranın tamamını kaplamıyor: altındaki listeden bir şerit görünsün.
    private var width: CGFloat {
        min(310, UIScreen.main.bounds.width * 0.82)
    }

    /// Menü kapalıyken durduğu yer.
    private var hidden: CGFloat { width + 16 }

    /// Kaydırmanın başlayabileceği sağ kenar şeridi.
    ///
    /// Dar tutuluyor: debe destesindeki kart da yatay kaydırılıyor ve o
    /// kart kenardan 14 punto içeride duruyor.
    private static var edge: CGFloat { 20 }

    /// Menünün o anki yeri: kapalı/açık konum + parmağın götürdüğü kadar.
    private var offset: CGFloat {
        min(hidden, max(0, (isOpen ? 0 : hidden) + drag))
    }

    /// 0 tamamen kapalı, 1 tamamen açık. Karartma buna göre koyulaşıyor.
    private var progress: CGFloat {
        1 - offset / hidden
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content()
                // Sağ kenardan içeri kaydırma menüyü açıyor. Simultaneous:
                // altındaki listenin kendi kaydırması çalışmaya devam etsin.
                .simultaneousGesture(openDrag)

            if progress > 0.01 {
                Color.black.opacity(0.35 * progress)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .gesture(closeDrag)
                    // Sürüklerken içerik hâlâ parmağı görsün; karartma
                    // ancak menü açıldıktan sonra dokunuş yutuyor.
                    .allowsHitTesting(isOpen)
            }

            SideMenu(close: close)
                .frame(width: width)
                .frame(maxHeight: .infinity)
                .background(Palette.surface.ignoresSafeArea())
                .shadow(color: .black.opacity(0.25 * progress), radius: 12, x: -4)
                // Kapalıyken ekranın sağında bekliyor.
                .offset(x: offset)
                // Kapalıyken dokunuşları yutmasın.
                .allowsHitTesting(isOpen)
                .gesture(closeDrag)
        }
    }

    /// Sağ kenardan sola: menüyü çekip çıkarıyor.
    private var openDrag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                guard canOpen(value) else { return }
                // Sola gidiş negatif; menü o kadar içeri geliyor.
                drag = min(0, value.translation.width)
            }
            .onEnded { value in
                guard canOpen(value) else {
                    drag = 0
                    return
                }
                // Yarı yolu geçtiyse ya da hızlı fiskeyse açılıyor.
                let flick = -value.predictedEndTranslation.width > 140
                if -value.translation.width > width * 0.4 || flick {
                    open()
                } else {
                    settle()
                }
            }
    }

    /// Menünün üstünde sağa: kapatıyor.
    private var closeDrag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard isOpen else { return }
                drag = max(0, value.translation.width)
            }
            .onEnded { value in
                guard isOpen else { return }
                if value.translation.width > 60 || value.predictedEndTranslation.width > 140 {
                    close()
                } else {
                    settle()
                }
            }
    }

    /// Açma kaydırması yalnızca kapalıyken, sağ kenardan başlayan ve yatay
    /// olan harekette geçerli: dikey kaydırmayı bozmasın.
    private func canOpen(_ value: DragGesture.Value) -> Bool {
        guard !isOpen else { return false }
        guard value.startLocation.x > UIScreen.main.bounds.width - Self.edge else { return false }
        return abs(value.translation.width) > abs(value.translation.height)
    }

    private func open() {
        withAnimation(.easeOut(duration: 0.25)) {
            drag = 0
            isOpen = true
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.25)) {
            drag = 0
            isOpen = false
        }
    }

    /// Eşiğin altında bırakıldı: menü olduğu yere geri yaslanıyor.
    private func settle() {
        withAnimation(.easeOut(duration: 0.2)) { drag = 0 }
    }
}

/// Menünün içeriği.
struct SideMenu: View {
    let close: () -> Void

    @EnvironmentObject private var auth: AuthSession
    @State private var showLogin = false
    @State private var signingOut = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if auth.isLoggedIn {
                row("çıkış yap", icon: "rectangle.portrait.and.arrow.right", busy: signingOut) {
                    signingOut = true
                    Task {
                        await auth.signOut()
                        signingOut = false
                        close()
                    }
                }
            } else {
                row("yazar girişi", icon: "person.crop.circle.badge.plus") {
                    showLogin = true
                }
            }

            Spacer()

            Text(Self.versionString)
                .font(.caption2)
                .foregroundStyle(Palette.meta)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showLogin) {
            LoginView { nick in
                auth.signedIn(nick: nick)
                close()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: auth.isLoggedIn ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 34))
                .foregroundStyle(Palette.sage)

            VStack(alignment: .leading, spacing: 2) {
                Text(auth.nick ?? (auth.isLoggedIn ? "yazar" : "misafir"))
                    .font(.headline)
                    .foregroundStyle(Palette.text)
                Text(auth.isLoggedIn ? "girişli" : "giriş yapılmadı")
                    .font(.caption)
                    .foregroundStyle(Palette.meta)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        // Üst bar kadar aşağıdan başlasın.
        .padding(.top, 68)
        .padding(.bottom, 18)
    }

    private func row(
        _ title: String,
        icon: String,
        busy: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if busy {
                    BrandLoader(width: 14, tint: Palette.sage)
                        .frame(width: 22, alignment: .leading)
                } else {
                    Image(systemName: icon)
                        .frame(width: 22, alignment: .leading)
                }
                Text(title)
                Spacer(minLength: 0)
            }
            .font(.system(size: 16))
            .foregroundStyle(Palette.text)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(busy)
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "şükela lite \(short) (\(build))"
    }
}
