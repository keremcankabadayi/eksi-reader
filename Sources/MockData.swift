import Foundation

/// Ağ katmanı yazılana kadar kullanılan sahte kaynak.
struct MockFeedProvider: FeedProviding {
    static let shared = MockFeedProvider()

    func topics(for feed: Feed) -> [Topic] {
        switch feed {
        case .gundem: return Self.gundem
        case .debe: return Self.debe
        }
    }

    func entries(for topic: Topic) -> [Entry] {
        Self.entries.map { entry in
            Entry(
                id: topic.id * 1000 + entry.id,
                body: entry.body,
                author: entry.author,
                date: entry.date,
                favCount: entry.favCount
            )
        }
    }

    private static let gundem: [Topic] = [
        Topic(id: 1, title: "kendi ekşi istemcini yazmak", entryCount: 142),
        Topic(id: 2, title: "sideloading", entryCount: 37),
        Topic(id: 3, title: "reklamsız uygulama kullanmanın hazzı", entryCount: 512),
        Topic(id: 4, title: "swiftui", entryCount: 89),
        Topic(id: 5, title: "github actions macos runner", entryCount: 12),
        Topic(id: 6, title: "26 ağustos 2026", entryCount: 1043),
    ]

    private static let debe: [Topic] = [
        Topic(id: 101, title: "apple'ın 99 dolarlık geliştirici programı", entryCount: 208),
        Topic(id: 102, title: "7 günde bir uygulama yenilemek", entryCount: 64),
        Topic(id: 103, title: "xcode kurulum boyutu", entryCount: 331),
    ]

    private static let entries: [Entry] = [
        Entry(
            id: 1,
            body: "iskelet ayakta. veri katmanı henüz bağlı değil, gördüğün her şey sahte. "
                + "amaç önce telefona kurulum hattının çalıştığını görmek.",
            author: "kerem",
            date: "26.08.2026 18:40",
            favCount: 24
        ),
        Entry(
            id: 2,
            body: "buradaki asıl mesele derlemenin mac'te değil, github actions üzerinde koşması. "
                + "push at, birkaç dakika sonra telefonda güncelleme çıksın.",
            author: "kerem",
            date: "26.08.2026 18:44",
            favCount: 11
        ),
        Entry(
            id: 3,
            body: "yazı boyutunu ayarlar sekmesinden değiştirebilirsin. "
                + "ayarlarda ayrıca telefondaki sürüm numarası yazıyor, hangi build'in yüklü olduğunu oradan doğrula.",
            author: "kerem",
            date: "26.08.2026 18:51",
            favCount: 3
        ),
    ]
}
