import XCTest
@testable import SukelaCore

final class FavoriteListParserTests: XCTestCase {
    func testReadsNicks() throws {
        let nicks = try FavoriteListParser.parse(html: try Fixture.html("favorites"))
        XCTAssertEqual(nicks, ["kerem", "başka yazar"])
    }

    /// Çaylakları açan bağlantı yazar değil, listeye girmiyor.
    func testSkipsNonAuthorLinks() throws {
        let nicks = try FavoriteListParser.parse(html: try Fixture.html("favorites"))
        XCTAssertFalse(nicks.contains { $0.contains("çaylak") })
    }

    /// Bağlantının içi ikonsa nick yoldan okunuyor.
    func testFallsBackToPath() throws {
        let nicks = try FavoriteListParser.parse(
            html: #"<div><a href="/biri/sessiz-yazar"><img src="x.png"></a></div>"#
        )
        XCTAssertEqual(nicks, ["sessiz-yazar"])
    }

    func testEmptyListIsEmpty() throws {
        XCTAssertTrue(try FavoriteListParser.parse(html: "<div></div>").isEmpty)
    }

    func testEndpointCarriesEntryId() {
        XCTAssertEqual(
            EksiEndpoint.favoriteAuthors(entryId: "98765").url?.absoluteString,
            "https://eksisozluk.com/entry/favorileyenler?entryId=98765"
        )
    }
}
