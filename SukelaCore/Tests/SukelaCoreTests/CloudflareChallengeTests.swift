import XCTest
@testable import SukelaCore

final class CloudflareChallengeTests: XCTestCase {
    func testDetectsChallengeFromHeader() {
        XCTAssertTrue(CloudflareChallenge.isChallenge(headers: ["cf-mitigated": "challenge"]))
        // Başlık adı büyük/küçük harf duyarsız gelebiliyor.
        XCTAssertTrue(CloudflareChallenge.isChallenge(headers: ["CF-Mitigated": "Challenge"]))
    }

    func testDetectsChallengeFromTitle() {
        XCTAssertTrue(CloudflareChallenge.isChallenge(title: "Just a moment..."))
        XCTAssertTrue(CloudflareChallenge.isChallenge(title: "Lütfen Bekleyiniz"))
    }

    func testDetectsChallengeFromHTMLMarkers() throws {
        let html = try Fixture.html("cloudflare")
        XCTAssertTrue(CloudflareChallenge.isChallenge(html: html))
    }

    func testRealPageIsNotChallenge() throws {
        let html = try Fixture.html("gundem")
        XCTAssertFalse(CloudflareChallenge.isChallenge(title: "gündem - ekşi sözlük", html: html))
    }

    func testReadyRequiresSuccessStatus() throws {
        let html = try Fixture.html("gundem")
        XCTAssertTrue(CloudflareChallenge.isReady(statusCode: 200, title: "gündem", html: html))
        XCTAssertFalse(CloudflareChallenge.isReady(statusCode: 403, title: "gündem", html: html))
        XCTAssertFalse(CloudflareChallenge.isReady(statusCode: nil, title: "gündem", html: html))
    }

    func testReadyRejectsChallengePage() throws {
        let html = try Fixture.html("cloudflare")
        XCTAssertFalse(
            CloudflareChallenge.isReady(statusCode: 200, title: "Just a moment...", html: html)
        )
    }

    func testReadyRejectsEmptyTitle() {
        XCTAssertFalse(CloudflareChallenge.isReady(statusCode: 200, title: "  ", html: "<html></html>"))
    }
}
