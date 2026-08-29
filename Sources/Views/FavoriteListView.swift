import SwiftUI
import SukelaCore

/// Bir entry'yi favorileyen yazarlar.
///
/// Liste entry ile birlikte gelmiyor; Ekşi ayrı bir adreste parça HTML
/// olarak veriyor, kart açılınca çekiliyor.
struct FavoriteListView: View {
    let entry: Entry
    var provider: FeedProviding = EksiFeedProvider.shared

    @Environment(\.dismiss) private var dismiss
    @State private var nicks: [String] = []
    @State private var phase: LoadPhase = .idle

    var body: some View {
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.base)
                .navigationTitle("favorileyenler")
                .navigationBarTitleDisplayMode(.inline)
                .eksiNavigationBar()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("kapat") { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
        .task { await load() }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .idle, .loading:
            BrandLoadingView()
        case let .failed(failure):
            ErrorView(failure: failure) { await load() }
        case .loaded where nicks.isEmpty:
            // Sayı sıfırdan büyükken buraya düşmek Ekşi'nin işaretlemesi
            // değişti demek; sessizce boş liste göstermek yanıltıcı olur.
            Text(
                entry.favoriteCount > 0
                    ? "liste okunamadı"
                    : "kimse favorilememiş"
            )
            .font(.callout)
            .foregroundStyle(Palette.meta)
        case .loaded:
            List {
                ForEach(nicks, id: \.self) { nick in
                    Text(nick)
                        .font(.callout)
                        .foregroundStyle(Palette.nick)
                        .listRowBackground(Palette.base)
                        .listRowSeparatorTint(Palette.surface)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func load() async {
        guard phase == .idle || isFailed else { return }
        phase = .loading
        do {
            nicks = try await provider.favoriteAuthors(entryId: entry.id)
            phase = .loaded
        } catch {
            nicks = []
            phase = .failed(FailureInfo(error))
        }
    }

    private var isFailed: Bool {
        if case .failed = phase { return true }
        return false
    }
}

#Preview {
    FavoriteListView(
        entry: Entry(
            id: "1",
            contentHTML: "deneme",
            author: Author(id: "1", nick: "kerem"),
            date: "26.08.2026 18:40",
            favoriteCount: 3
        ),
        provider: MockFeedProvider.shared
    )
}
