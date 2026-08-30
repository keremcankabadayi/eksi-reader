import XCTest
@testable import SukelaCore

final class EntryPageParserTests: XCTestCase {
    private func page() throws -> TopicPage {
        try EntryPageParser.parse(html: try Fixture.html("topic"))
    }

    func testParsesTopicHeader() throws {
        let page = try page()
        XCTAssertEqual(page.title, "kendi ekşi istemcini yazmak")
        XCTAssertEqual(page.slug, "kendi-eksi-istemcini-yazmak")
        XCTAssertEqual(page.topicId, "123456")
    }

    func testParsesEveryEntry() throws {
        XCTAssertEqual(try page().entries.count, 2)
    }

    func testParsesEntryFields() throws {
        let entry = try XCTUnwrap(try page().entries.first)
        XCTAssertEqual(entry.id, "98765")
        XCTAssertEqual(entry.author.nick, "kerem")
        XCTAssertEqual(entry.author.id, "42")
        XCTAssertEqual(entry.date, "26.08.2026 18:40")
        XCTAssertEqual(entry.favoriteCount, 24)
    }

    /// Gövde HTML olarak korunmalı: `bkz` bağlantıları düz metne çevrilince kayboluyor.
    func testKeepsContentAsHTML() throws {
        let entry = try XCTUnwrap(try page().entries.first)
        XCTAssertTrue(entry.contentHTML.contains("<a href=\"/?q=bkz\""))
        XCTAssertTrue(entry.contentHTML.contains("veri katmanı"))
    }

    func testResolvesProtocolRelativeAvatarURL() throws {
        let entry = try XCTUnwrap(try page().entries.first)
        XCTAssertEqual(entry.author.avatarURL, "https://img.ekstat.com/profiles/kerem.jpg")
    }

    func testDropsDefaultAvatar() throws {
        let entry = try XCTUnwrap(try page().entries.last)
        XCTAssertNil(entry.author.avatarURL)
    }

    /// Her entry kendi gövdesini ve tarihini taşımalı; indeks eşlemesi yapmıyoruz.
    func testEntriesDoNotShareContent() throws {
        let entries = try page().entries
        XCTAssertTrue(entries[1].contentHTML.contains("ikinci entry"))
        XCTAssertEqual(entries[1].date, "26.08.2026 19:02 ~ 19:10")
        XCTAssertEqual(entries[1].favoriteCount, 0)
    }

    func testParsesPagination() throws {
        let page = try page()
        XCTAssertEqual(page.currentPage, 2)
        XCTAssertEqual(page.pageCount, 5)
    }

    /// Pager'ın sınıfı değişirse bile sayfa numarasını kaybetmemeliyiz;
    /// yoksa "N entry daha" satırı hiç çıkmıyor.
    func testFallsBackToPageCountAttribute() throws {
        let html = """
        <html><body><h1 id="title"></h1>
        <div class="sayfalama" data-currentpage="22" data-pagecount="30"></div>
        </body></html>
        """
        let page = try EntryPageParser.parse(html: html)
        XCTAssertEqual(page.currentPage, 22)
        XCTAssertEqual(page.pageCount, 30)
    }

    /// Ekşi "N entry daha" bağlantılarını kendisi koyuyor: listeden önceki
    /// öncekileri, sonraki sonrakileri açıyor. Sayıyı biz hesaplamıyoruz.
    func testParsesMoreLinks() throws {
        let page = try page()
        XCTAssertEqual(page.previousMore?.label, "10 entry daha")
        XCTAssertEqual(
            page.previousMore?.link,
            "/kendi-eksi-istemcini-yazmak--123456?focusto=98700"
        )
        XCTAssertEqual(page.nextMore?.label, "330 entry daha")
        XCTAssertEqual(
            page.nextMore?.link,
            "/kendi-eksi-istemcini-yazmak--123456?focusto=99000"
        )
    }

    func testNoMoreLinksWhenAbsent() throws {
        let html = "<html><body><h1 id=\"title\"></h1><ul id=\"entry-item-list\"></ul></body></html>"
        let page = try EntryPageParser.parse(html: html)
        XCTAssertNil(page.previousMore)
        XCTAssertNil(page.nextMore)
    }

    func testMissingPagerDefaultsToSinglePage() throws {
        let page = try EntryPageParser.parse(html: "<html><body><h1 id=\"title\"></h1></body></html>")
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertEqual(page.pageCount, 1)
        XCTAssertTrue(page.entries.isEmpty)
    }
}

// MARK: - İşaretleme değişirse

extension EntryPageParserTests {
    /// entry-item-list id'si değişirse sınıf üzerinden bulmalı.
    func testFallsBackToEntryListClass() throws {
        let html = """
        <html><body>
        <h1 id="title" data-title="x" data-slug="x" data-id="1"></h1>
        <ul class="entry-list">
          <li data-id="5" data-author="biri" data-author-id="9" data-favorite-count="3">
            <div class="content">gövde</div>
            <a class="entry-date permalink" href="/entry/5">01.01.2026 10:00</a>
          </li>
        </ul>
        </body></html>
        """
        let page = try EntryPageParser.parse(html: html)
        XCTAssertEqual(page.entries.count, 1)
        XCTAssertEqual(page.entries.first?.author.nick, "biri")
        XCTAssertEqual(page.entries.first?.favoriteCount, 3)
    }

    /// Liste sarmalayıcısı tamamen değişirse entry'nin kendi öznitelikleriyle bulmalı.
    func testFallsBackToEntryAttributes() throws {
        let html = """
        <html><body>
        <h1 id="title" data-title="x" data-slug="x" data-id="1"></h1>
        <div class="entries">
          <li data-id="7" data-author="baska" data-author-id="4" data-favorite-count="0">
            <div class="content">ikinci gövde</div>
            <a class="entry-date permalink" href="/entry/7">02.01.2026 11:00</a>
          </li>
        </div>
        </body></html>
        """
        let page = try EntryPageParser.parse(html: html)
        XCTAssertEqual(page.entries.count, 1)
        XCTAssertEqual(page.entries.first?.id, "7")
        XCTAssertEqual(page.entries.first?.plainText, "ikinci gövde")
    }

    /// Ekşi verilmiş oyu entry özniteliğinde söylüyor; girişsiz sayfada
    /// öznitelik hiç olmuyor, o zaman oy yok.
    func testReadsGivenVote() throws {
        let entries = try page().entries
        XCTAssertEqual(entries[0].vote, .up)
        XCTAssertNil(entries[1].vote)
    }

    func testReadsDownVote() throws {
        let html = """
        <html><body>
        <ul id="entry-item-list">
          <li data-id="9" data-author="a" data-author-id="1" data-favorite-count="0"
              data-isliked="false" data-isdisliked="true">
            <div class="content">eksi oy</div>
            <a class="entry-date permalink" href="/entry/9">02.01.2026 11:00</a>
          </li>
        </ul>
        </body></html>
        """
        XCTAssertEqual(try EntryPageParser.parse(html: html).entries.first?.vote, .down)
    }

    /// Favori de oy gibi entry'nin özniteliğinde; girişsiz sayfada yok.
    func testReadsFavoriteFlag() throws {
        let html = """
        <html><body>
        <ul id="entry-item-list">
          <li data-id="9" data-author="a" data-author-id="1" data-favorite-count="4"
              data-isfavorite="true">
            <div class="content">favorili</div>
            <a class="entry-date permalink" href="/entry/9">02.01.2026 11:00</a>
          </li>
          <li data-id="10" data-author="b" data-author-id="2" data-favorite-count="0">
            <div class="content">favorisiz</div>
            <a class="entry-date permalink" href="/entry/10">02.01.2026 11:01</a>
          </li>
        </ul>
        </body></html>
        """
        let entries = try EntryPageParser.parse(html: html).entries
        XCTAssertTrue(entries[0].isFavorite)
        XCTAssertFalse(entries[1].isFavorite)
    }
}
