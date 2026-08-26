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

    func testMissingPagerDefaultsToSinglePage() throws {
        let page = try EntryPageParser.parse(html: "<html><body><h1 id=\"title\"></h1></body></html>")
        XCTAssertEqual(page.currentPage, 1)
        XCTAssertEqual(page.pageCount, 1)
        XCTAssertTrue(page.entries.isEmpty)
    }
}
