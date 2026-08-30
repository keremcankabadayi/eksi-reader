import XCTest
@testable import SukelaCore

final class FavoriteParserTests: XCTestCase {
    /// Sitenin kendi JS'inin okuduğu şekil: alanlar kökte, sayı `Count`.
    func testParsesFlatSuccess() throws {
        let result = try FavoriteParser.parse(json: #"{"Success":true,"Count":25}"#)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.count, 25)
        XCTAssertNil(result.message)
    }

    func testParsesFailureMessage() throws {
        let result = try FavoriteParser.parse(
            json: #"{"Success":false,"ErrorMessage":"anlaşılmaz hatalar oldu"}"#
        )
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.message, "anlaşılmaz hatalar oldu")
        XCTAssertNil(result.count)
    }

    /// Oy ucundaki gibi sarmalanmış gelirse de okunuyor.
    func testParsesWrappedSuccess() throws {
        let result = try FavoriteParser.parse(
            json: #"{"SuccessData":{"Success":true},"Count":3}"#
        )
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.count, 3)
    }

    func testRejectsNoLogin() {
        XCTAssertThrowsError(try FavoriteParser.parse(json: "nologin")) { error in
            XCTAssertEqual(error as? FavoriteParseError, .notLoggedIn)
        }
    }

    func testRejectsHTML() {
        XCTAssertThrowsError(try FavoriteParser.parse(json: "<html>giriş</html>")) { error in
            XCTAssertEqual(error as? FavoriteParseError, .notJSON)
        }
    }

    /// Success alanı hiç yoksa "oldu" saymıyoruz.
    func testRejectsMissingSuccess() {
        XCTAssertThrowsError(try FavoriteParser.parse(json: #"{"Count":4}"#)) { error in
            XCTAssertEqual(error as? FavoriteParseError, .noSuccessField)
        }
    }
}
