import Foundation
import SukelaCore

/// SwiftUI önizlemeleri için sahte kaynak. Uygulama artık gerçek veriyi
/// kullanıyor; bu yalnızca ağ olmadan ekran çizebilmek için duruyor.
struct MockFeedProvider: FeedProviding {
    static let shared = MockFeedProvider()

    func topics(for feed: Feed) async throws -> [Topic] {
        switch feed {
        case .gundem: return Self.gundem
        case .debe: return Self.debe
        }
    }

    func topicPage(link: String, page: Int?) async throws -> TopicPage {
        // page nil ise "kaldığın yer": önizlemede üstteki "N entry daha"
        // satırının göründüğü hâli taklit ediyor.
        let current = page ?? 22
        return TopicPage(
            title: "örnek başlık",
            slug: "ornek-baslik",
            topicId: "1",
            entries: Self.entries(page: current),
            currentPage: current,
            pageCount: 30
        )
    }

    private static let gundem: [Topic] = [
        Topic(id: "1", title: "kendi ekşi istemcini yazmak", slug: "a", entryCount: "142", link: "/a--1"),
        Topic(id: "2", title: "sideloading", slug: "b", entryCount: "37", link: "/b--2"),
        Topic(id: "3", title: "swiftui", slug: "c", entryCount: "89", link: "/c--3"),
    ]

    private static let debe: [Topic] = [
        Topic(id: "101", title: "7 günde bir uygulama yenilemek", slug: "d", entryCount: "64", link: "/d--101"),
    ]

    /// Sayfa başına birkaç entry; id'ler sayfa numarasını taşıyor ki önceki
    /// sayfa yüklendiğinde liste çakışmasın.
    private static func entries(page: Int) -> [Entry] {
        (1...3).map { index in
            Entry(
                id: "\(page)-\(index)",
                contentHTML: "sayfa \(page), entry \(index). önizleme için sahte veri.",
                author: Author(id: "1", nick: "kerem"),
                date: "26.08.2026 18:40",
                favoriteCount: index * 8
            )
        }
    }
}
