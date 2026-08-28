import SwiftUI
import UIKit
import WebKit

/// Uygulama içinde açılacak harici bağlantı. `sheet(item:)` için kimlikli.
struct PopupLink: Identifiable, Hashable {
    let url: URL
    /// Gövdedeki bağlantı metni; boşsa alan adı gösteriliyor.
    let label: String

    var id: String { url.absoluteString + "\u{1}" + label }

    /// Doğrudan görsel bağlantısı mı? Öyleyse web yerine yakınlaştırılabilir
    /// görüntüleyici açılıyor; WKWebView çıplak görseli sığdırmıyor.
    var isImage: Bool {
        ["jpg", "jpeg", "png", "gif", "webp", "heic", "bmp"]
            .contains(url.pathExtension.lowercased())
    }

    var title: String {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return url.host?.replacingOccurrences(of: "www.", with: "") ?? url.absoluteString
    }
}

/// Harici bağlantıları Safari'ye atmadan, ekranın üstüne gelen bir kartta açıyor.
///
/// Çerez deposu uygulamanın kendi deposu (`WKWebsiteDataStore.default()`), yani
/// Ekşi profil sayfaları girişliyken girişli açılıyor. Bkz. `LoginView`.
struct WebPopupView: View {
    let link: PopupLink

    @Environment(\.dismiss) private var dismiss
    @State private var progress: Double = 0
    @State private var loading = false
    @State private var pageTitle: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(pageTitle ?? link.title)
                .navigationBarTitleDisplayMode(.inline)
                .eksiNavigationBar()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                UIPasteboard.general.string = link.url.absoluteString
                            } label: {
                                Label("bağlantıyı kopyala", systemImage: "link")
                            }
                            ShareLink(item: link.url) {
                                Label("paylaş", systemImage: "square.and.arrow.up")
                            }
                            Button {
                                UIApplication.shared.open(link.url)
                            } label: {
                                Label("safari'de aç", systemImage: "safari")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
                // Yükleme çubuğu başlığın hemen altında, ince bir şerit.
                .safeAreaInset(edge: .top, spacing: 0) {
                    if loading {
                        ProgressView(value: progress)
                            .progressViewStyle(.linear)
                            .tint(Palette.link)
                            .frame(height: 2)
                    }
                }
        }
        .tint(Palette.link)
    }

    @ViewBuilder
    private var content: some View {
        if link.isImage {
            ZoomableImageView(url: link.url)
                .background(Palette.base)
        } else {
            PopupWebView(url: link.url, progress: $progress, loading: $loading, title: $pageTitle)
                .background(Palette.base)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

/// Sayfayı çizen `WKWebView`. İlerleme ve başlık KVO ile dışarı veriliyor.
private struct PopupWebView: UIViewRepresentable {
    let url: URL
    @Binding var progress: Double
    @Binding var loading: Bool
    @Binding var title: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(progress: $progress, loading: $loading, title: $title)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        // Gizli tarayıcı ve giriş ekranı ile aynı depo: Ekşi sayfaları girişli açılıyor.
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        context.coordinator.observe(webView)
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.stop()
        webView.stopLoading()
    }

    final class Coordinator: NSObject {
        @Binding private var progress: Double
        @Binding private var loading: Bool
        @Binding private var title: String?
        private var tokens: [NSKeyValueObservation] = []

        init(progress: Binding<Double>, loading: Binding<Bool>, title: Binding<String?>) {
            _progress = progress
            _loading = loading
            _title = title
        }

        func observe(_ webView: WKWebView) {
            tokens = [
                webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
                    Task { @MainActor in self?.progress = view.estimatedProgress }
                },
                webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
                    Task { @MainActor in self?.loading = view.isLoading }
                },
                webView.observe(\.title, options: [.new]) { [weak self] view, _ in
                    Task { @MainActor in
                        let value = view.title?.trimmingCharacters(in: .whitespacesAndNewlines)
                        self?.title = (value?.isEmpty == false) ? value : nil
                    }
                },
            ]
        }

        func stop() {
            tokens.forEach { $0.invalidate() }
            tokens = []
        }

        deinit { tokens.forEach { $0.invalidate() } }
    }
}

/// Doğrudan görsel bağlantıları için: sığdırılmış, çift dokunuşla ve çimdikle
/// yakınlaştırılabilir görüntüleyici.
private struct ZoomableImageView: View {
    let url: URL

    @State private var scale: CGFloat = 1
    @State private var committed: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    private static let maxScale: CGFloat = 6

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = min(max(committed * value, 1), Self.maxScale)
                                }
                                .onEnded { _ in
                                    committed = scale
                                    if scale == 1 { reset() }
                                },
                            DragGesture()
                                .onChanged { value in
                                    guard scale > 1 else { return }
                                    offset = CGSize(
                                        width: committedOffset.width + value.translation.width,
                                        height: committedOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in committedOffset = offset }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if scale > 1 {
                                reset()
                            } else {
                                scale = 3
                                committed = 3
                            }
                        }
                    }
            case .failure:
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                    Text("görsel yüklenemedi")
                        .font(.footnote)
                }
                .foregroundStyle(Palette.meta)
            default:
                BrandLoadingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func reset() {
        scale = 1
        committed = 1
        offset = .zero
        committedOffset = .zero
    }
}
