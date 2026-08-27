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
        TopicPage(
            title: "örnek başlık",
            slug: "ornek-baslik",
            topicId: "1",
            entries: Self.entries,
            currentPage: page ?? 1,
            pageCount: 1
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

    private static let entries: [Entry] = [
        Entry(
            id: "1",
            contentHTML: "önizleme için sahte entry. gerçek veri Ekşi'den geliyor.",
            author: Author(id: "1", nick: "kerem"),
            date: "26.08.2026 18:40",
            favoriteCount: 24
        ),
    ]
}
