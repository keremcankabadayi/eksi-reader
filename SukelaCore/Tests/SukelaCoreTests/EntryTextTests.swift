import XCTest
@testable import SukelaCore

final class EntryTextTests: XCTestCase {
    func testStripsTags() {
        XCTAssertEqual(
            EntryText.plainText(from: "iskelet <a href=\"/?q=bkz\" class=\"b\">bkz</a> ayakta"),
            "iskelet bkz ayakta"
        )
    }

    /// <br> satır sonu demek; SwiftSoup'un text()'i bunu yutuyor, korumamız gerekiyor.
    func testKeepsLineBreaks() {
        XCTAssertEqual(
            EntryText.plainText(from: "birinci satır<br>ikinci satır"),
            "birinci satır\nikinci satır"
        )
    }

    func testCollapsesTrailingWhitespace() {
        XCTAssertEqual(EntryText.plainText(from: "  metin  <br>  "), "metin")
    }

    func testDecodesEntities() {
        XCTAssertEqual(EntryText.plainText(from: "a &amp; b &lt;c&gt;"), "a & b <c>")
    }

    func testPlainTextOnEntryUsesContentHTML() throws {
        let page = try EntryPageParser.parse(html: try Fixture.html("topic"))
        let entry = try XCTUnwrap(page.entries.first)
        XCTAssertEqual(entry.plainText, "iskelet ayakta, bkz veri katmanı.")
    }
}
