import SwiftUI

/// Ekranların yükleme durumu. Ekşi HTML'i değiştiğinde parser boş dönebiliyor,
/// o yüzden "boş" da bir hata hâli olarak gösteriliyor — sessizce boş liste
/// göstermek sorunu gizler.
enum LoadPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

struct LoadingRow: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowSeparator(.hidden)
        .padding(.vertical, 32)
    }
}

struct ErrorRow: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("tekrar dene") {
                Task { await retry() }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .listRowSeparator(.hidden)
        .padding(.vertical, 32)
    }
}
