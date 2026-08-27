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

    /// Sayfanın üstündeki "N entry daha" bağlantısı; başlık ortadan
    /// açıldığında Ekşi bunu kendisi koyuyor.
    public let previousMore: MoreLink?
    /// Sayfanın altındaki "N entry daha" bağlantısı.
    public let nextMore: MoreLink?

    public init(
        title: String,
        slug: String,
        topicId: String,
        entries: [Entry],
        currentPage: Int,
        pageCount: Int,
        previousMore: MoreLink? = nil,
        nextMore: MoreLink? = nil
    ) {
        self.title = title
        self.slug = slug
        self.topicId = topicId
        self.entries = entries
        self.currentPage = currentPage
        self.pageCount = pageCount
        self.previousMore = previousMore
        self.nextMore = nextMore
    }
}

/// Ekşi'nin "şu kadar entry daha var" bağlantısı.
///
/// Sayıyı biz hesaplamıyoruz: sayfa başına entry sayısı sabit değil ve
/// başlık `focusto` ile ortadan açıldığında tahmin tutmuyor. Ekşi ne
/// yazıyorsa onu gösteriyoruz.
public struct MoreLink: Hashable, Sendable {
    /// Bağlantının kendi metni, örneğin "10 entry daha".
    public let label: String
    /// Göreli yol, örneğin "/baslik--123?focusto=185898249".
    public let link: String

    public init(label: String, link: String) {
        self.label = label
        self.link = link
    }
}
