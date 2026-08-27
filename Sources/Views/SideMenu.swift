import SwiftUI
import UIKit

/// Sağdan açılan menü. Üst bardaki ikon açıyor, karartmaya dokunmak ya da
/// sağa sürüklemek kapatıyor.
///
/// Sekme çubuğunun da üstünü kaplaması gerektiği için `RootView`'un en
/// dışına, TabView'i sarmalayarak konuluyor.
struct DrawerContainer<Content: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder var content: () -> Content

    /// Ekranın tamamını kaplamıyor: altındaki listeden bir şerit görünsün.
    private var width: CGFloat {
        min(310, UIScreen.main.bounds.width * 0.82)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content()

            if isOpen {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { close() }
            }

            SideMenu(close: close)
                .frame(width: width)
                .frame(maxHeight: .infinity)
                .background(Palette.surface.ignoresSafeArea())
                .shadow(color: .black.opacity(isOpen ? 0.25 : 0), radius: 12, x: -4)
                // Kapalıyken ekranın sağında bekliyor.
                .offset(x: isOpen ? 0 : width + 16)
                // Kapalıyken dokunuşları yutmasın.
                .allowsHitTesting(isOpen)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onEnded { value in
                            if value.translation.width > 60 { close() }
                        }
                )
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.25)) { isOpen = false }
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
