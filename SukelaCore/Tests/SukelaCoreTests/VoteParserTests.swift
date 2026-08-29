import XCTest
@testable import SukelaCore

final class VoteParserTests: XCTestCase {
    /// Sitenin kendi JS'inin okuduğu şekil: sonuç `SuccessData` içinde.
    func testParsesWrappedSuccess() throws {
        let result = try VoteParser.parse(
            json: #"{"SuccessData":{"Success":true,"Message":"oldu"},"LikeCount":12}"#
        )
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "oldu")
        XCTAssertFalse(result.alreadyVotedAnonymously)
    }

    func testParsesWrappedFailure() throws {
        let result = try VoteParser.parse(
            json: #"{"SuccessData":{"Success":false,"Message":"kendi entry'ne oy veremezsin"}}"#
        )
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.message, "kendi entry'ne oy veremezsin")
    }

    func testReadsAnonymousVoteFlag() throws {
        let result = try VoteParser.parse(
            json: #"{"SuccessData":{"Success":false,"Message":"kayıt ol","AlreadyVotedAnonymously":true}}"#
        )
        XCTAssertTrue(result.alreadyVotedAnonymously)
    }

    /// Sarmalayansız düz şekil de kabul ediliyor.
    func testParsesFlatShape() throws {
        let result = try VoteParser.parse(json: #"{"Success":true,"Message":null}"#)
        XCTAssertTrue(result.success)
        XCTAssertNil(result.message)
    }

    func testAcceptsLowercaseKeys() throws {
        let result = try VoteParser.parse(json: #"{"success":true,"errormessage":"tamam"}"#)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.message, "tamam")
    }

    /// Oturumsuz istekte Ekşi JSON değil, düz "nologin" döndürüyor.
    func testDetectsNoLogin() {
        XCTAssertThrowsError(try VoteParser.parse(json: "nologin")) { error in
            XCTAssertEqual(error as? VoteParseError, .notLoggedIn)
        }
    }

    /// Oturum düşünce sayfa geliyor; "oldu" saymıyoruz.
    func testRejectsHTMLResponse() {
        XCTAssertThrowsError(try VoteParser.parse(json: "<!DOCTYPE html><html></html>"))
    }

    func testRejectsJSONWithoutSuccessField() {
        XCTAssertThrowsError(try VoteParser.parse(json: #"{"LikeCount":3}"#))
    }

    func testEndpointPaths() {
        XCTAssertEqual(EksiEndpoint.vote.url?.absoluteString, "https://eksisozluk.com/entry/vote")
        XCTAssertEqual(
            EksiEndpoint.removeVote.url?.absoluteString,
            "https://eksisozluk.com/entry/removevote"
        )
    }
}
