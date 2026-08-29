import XCTest
@testable import SukelaCore

final class VoteParserTests: XCTestCase {
    func testParsesSuccess() throws {
        let result = try VoteParser.parse(json: #"{"Success":true,"Message":null,"Rate":5}"#)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.message)
    }

    func testParsesFailureWithMessage() throws {
        let result = try VoteParser.parse(json: #"{"Success":false,"Message":"giriş yapmalısınız"}"#)
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.message, "giriş yapmalısınız")
    }

    /// Alan adları uçtan uca aynı değil; büyük/küçük harf ayırmıyoruz.
    func testAcceptsLowercaseKeys() throws {
        let result = try VoteParser.parse(json: #"{"success":true,"message":"tamam"}"#)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "tamam")
    }

    /// Oturum düşünce Ekşi JSON yerine sayfa döndürüyor; "oldu" saymıyoruz.
    func testRejectsHTMLResponse() {
        XCTAssertThrowsError(try VoteParser.parse(json: "<!DOCTYPE html><html></html>"))
    }

    func testRejectsJSONWithoutSuccessField() {
        XCTAssertThrowsError(try VoteParser.parse(json: #"{"Rate":3}"#))
    }

    func testReadsVerificationTokenFromHiddenInput() throws {
        let html = try Fixture.html("token")
        XCTAssertEqual(VoteParser.verificationToken(html: html), "CfDJ8-test-token")
    }

    func testReadsVerificationTokenFromBrokenMarkup() {
        let html = #"<input name="__RequestVerificationToken" value="abc123""#
        XCTAssertEqual(VoteParser.verificationToken(html: html), "abc123")
    }

    func testMissingTokenIsNil() throws {
        XCTAssertNil(VoteParser.verificationToken(html: try Fixture.html("gundem")))
    }

    func testEndpointPaths() {
        XCTAssertEqual(EksiEndpoint.vote.url?.absoluteString, "https://eksisozluk.com/entry/vote")
        XCTAssertEqual(
            EksiEndpoint.removeVote.url?.absoluteString,
            "https://eksisozluk.com/entry/removevote"
        )
    }
}
