import SwiftUI
import UIKit

/// Bir hatanın ekranda gösterilecek hâli.
struct FailureInfo: Equatable {
    let message: String
    /// Ayrıştırma boş döndüğünde ne geldiğini anlatan teşhis metni.
    /// Ekşi işaretlemeyi değiştirdiğinde tahmin etmek yerine bakabilelim diye.
    let details: String?

    init(_ error: Error) {
        message = error.localizedDescription
        details = (error as? EmptyParseError)?.diagnostics
    }

    init(message: String, details: String? = nil) {
        self.message = message
        self.details = details
    }
}

/// Ekranların yükleme durumu.
enum LoadPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(FailureInfo)
}

/// Ekran boşken bekleme: uygulama işaretinin animasyonlu hâli.
struct LoadingRow: View {
    var body: some View {
        BrandLoadingView()
    }
}

struct ErrorView: View {
    let failure: FailureInfo
    let retry: () async -> Void

    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(failure.message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("tekrar dene") {
                Task { await retry() }
            }
            .buttonStyle(.bordered)

            if let details = failure.details {
                DisclosureGroup("detaylar", isExpanded: $showDetails) {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            UIPasteboard.general.string = details
                        } label: {
                            Label("kopyala", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(.bordered)

                        Text(details)
                            .font(.system(size: 11, design: .monospaced))
                            .monospacedFont()
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 8)
                }
                .font(.caption)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
