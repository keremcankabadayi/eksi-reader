import Foundation

/// Bir başlık. `entryCount` kasten String: Ekşi "12" de yazıyor "1,2k" de.
public struct Topic: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let slug: String
    public let entryCount: String
    /// Sitedeki göreli yol, örneğin "/kendi-eksi-istemcini-yazmak--123456".
    public let link: String

    public init(id: String, title: String, slug: String, entryCount: String, link: String) {
        self.id = id
        self.title = title
        self.slug = slug
        self.entryCount = entryCount
        self.link = link
    }
}

public struct Author: Hashable, Sendable {
    public let id: String
    public let nick: String
    public let avatarURL: String?

    public init(id: String, nick: String, avatarURL: String? = nil) {
        self.id = id
        self.nick = nick
        self.avatarURL = avatarURL
    }
}

public struct Entry: Identifiable, Hashable, Sendable {
    public let id: String
    /// Gövde HTML olarak saklanıyor: Ekşi'de bağlantılar ve `bkz` referansları var,
    /// düz metne çevirmek onları kaybettiriyor. Görüntüleme katmanı karar versin.
    public let contentHTML: String
    public let author: Author
    public let date: String
    public let favoriteCount: Int

    public init(
        id: String,
        contentHTML: String,
        author: Author,
        date: String,
        favoriteCount: Int
    ) {
        self.id = id
        self.contentHTML = contentHTML
        self.author = author
        self.date = date
        self.favoriteCount = favoriteCount
    }
}

/// Bir başlık sayfasının tamamı.
public struct TopicPage: Hashable, Sendable {
    public let title: String
    public let slug: String
    public let topicId: String
    public let entries: [Entry]
    public let currentPage: Int
    public let pageCount: Int

    /// Ekşi bir sayfada en fazla 10 entry gösteriyor. Sunucu bu sayıyı
    /// söylemiyor; sayfa numarasından entry sayısına geçebilmek için burada.
    public static let entriesPerPage = 10

    /// Bu sayfadan önce kaç entry var. Başlık ortadan açıldığında üstteki
    /// "N entry daha" satırında gösterilen sayı.
    public var precedingEntryCount: Int {
        max(currentPage - 1, 0) * Self.entriesPerPage
    }

    /// Yüklenecek bir önceki sayfa; ilk sayfadaysak nil.
    public var previousPage: Int? {
        currentPage > 1 ? currentPage - 1 : nil
    }

    public init(
        title: String,
        slug: String,
        topicId: String,
        entries: [Entry],
        currentPage: Int,
        pageCount: Int
    ) {
        self.title = title
        self.slug = slug
        self.topicId = topicId
        self.entries = entries
        self.currentPage = currentPage
        self.pageCount = pageCount
    }
}
