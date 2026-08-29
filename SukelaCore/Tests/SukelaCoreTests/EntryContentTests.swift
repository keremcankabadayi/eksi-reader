import XCTest
@testable import SukelaCore

final class EntryLinkTests: XCTestCase {
    func testBkzLookupIsTopic() {
        XCTAssertEqual(EntryLink.classify(href: "/?q=veri+katmani"), .topic(link: "/?q=veri+katmani"))
    }

    func testTopicPathKeepsQuery() {
        XCTAssertEqual(
            EntryLink.classify(href: "/kendi-eksi-istemcini-yazmak--123456?a=popular"),
            .topic(link: "/kendi-eksi-istemcini-yazmak--123456?a=popular")
        )
    }

    func testEntryPermalink() {
        XCTAssertEqual(EntryLink.classify(href: "/entry/98765"), .entry(id: "98765"))
    }

    func testProfile() {
        XCTAssertEqual(EntryLink.classify(href: "/biri/kerem"), .profile(nick: "kerem"))
    }

    func testAbsoluteInternalLinkStaysInternal() {
        XCTAssertEqual(
            EntryLink.classify(href: "https://eksisozluk.com/entry/1"),
            .entry(id: "1")
        )
    }

    func testForeignHostIsExternal() {
        XCTAssertEqual(
            EntryLink.classify(href: "https://example.com/x"),
            .external(url: "https://example.com/x")
        )
    }

    func testEmptyAndAnchorHrefsAreIgnored() {
        XCTAssertNil(EntryLink.classify(href: ""))
        XCTAssertNil(EntryLink.classify(href: "#"))
    }

    func testInAppLinkOnlyForTopicAndEntry() {
        XCTAssertEqual(EntryLink.topic(link: "/a--1").inAppLink, "/a--1")
        XCTAssertEqual(EntryLink.entry(id: "5").inAppLink, "/entry/5")
        XCTAssertNil(EntryLink.profile(nick: "kerem").inAppLink)
        XCTAssertNil(EntryLink.external(url: "https://example.com").inAppLink)
    }

    func testLookupLinkEncodesQuery() {
        XCTAssertEqual(EntryLink.lookupLink(for: "veri katmanı"), "/?q=veri%20katman%C4%B1")
        XCTAssertNil(EntryLink.lookupLink(for: "   "))
    }
}

final class EntryContentTests: XCTestCase {
    func testPlainTextIsSingleSegment() {
        let segments = EntryContent.segments(from: "iskelet ayakta")
        XCTAssertEqual(segments, [EntrySegment(text: "iskelet ayakta")])
    }

    /// Asıl şikâyet: bkz bağlantısı metne karışıp kayboluyordu.
    func testKeepsBkzLink() {
        let segments = EntryContent.segments(
            from: "iskelet ayakta, (bkz: <a href=\"/?q=veri katmanı\" class=\"b\">veri katmanı</a>)"
        )
        XCTAssertEqual(segments.count, 3)
        XCTAssertEqual(segments[0].text, "iskelet ayakta, (bkz: ")
        XCTAssertNil(segments[0].link)
        XCTAssertEqual(segments[1].text, "veri katmanı")
        XCTAssertEqual(segments[2].text, ")")
        XCTAssertNotNil(segments[1].link)
    }

    /// Gizli yıldız bkz: gövdede yalnızca "*" görünüyor, hedefi data-query'de.
    func testExpandsHiddenStarReference() {
        let segments = EntryContent.segments(
            from: "başlıyoruz<sup class=\"ab\"><a data-query=\"swiftui\">*</a></sup>"
        )
        XCTAssertEqual(segments.map(\.text), ["başlıyoruz (bkz: ", "swiftui", ")"])
        XCTAssertEqual(segments[1].link, .topic(link: "/?q=swiftui"))
    }

    func testExternalLinkGetsMarker() {
        let segments = EntryContent.segments(
            from: "<a rel=\"nofollow\" class=\"url\" href=\"https://example.com/x\">example.com</a>"
        )
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].text, "example.com \(EntryContent.externalMarker)")
        XCTAssertEqual(segments[0].link, .external(url: "https://example.com/x"))
    }

    func testKeepsLineBreaks() {
        let segments = EntryContent.segments(from: "birinci<br>ikinci")
        XCTAssertEqual(segments, [EntrySegment(text: "birinci\nikinci")])
    }

    func testTrimsSurroundingWhitespace() {
        XCTAssertEqual(
            EntryContent.segments(from: "  metin  <br>  "),
            [EntrySegment(text: "metin")]
        )
    }

    func testUnknownHrefFallsBackToPlainText() {
        let segments = EntryContent.segments(from: "<a href=\"#\">tıkla</a>")
        XCTAssertEqual(segments, [EntrySegment(text: "tıkla")])
    }

    func testExternalURLSurvivesUnescapedCharacters() throws {
        let link = EntryLink.external(url: "https://x.com/biri/status/1?s=20 ")
        let url = try XCTUnwrap(link.url)
        XCTAssertEqual(url.host, "x.com")
    }

    func testParsedEntryExposesSegments() throws {
        let page = try EntryPageParser.parse(html: try Fixture.html("topic"))
        let entry = try XCTUnwrap(page.entries.first)
        XCTAssertEqual(entry.segments.compactMap(\.link), [.topic(link: "/?q=bkz")])
    }
}
