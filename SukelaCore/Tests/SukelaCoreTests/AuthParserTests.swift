import XCTest
@testable import SukelaCore

final class AuthParserTests: XCTestCase {
    func testReadsNickWhenLoggedIn() throws {
        let state = try AuthParser.parse(html: try Fixture.html("auth-loggedin"))
        XCTAssertTrue(state.isLoggedIn)
        XCTAssertFalse(state.isIndeterminate)
        XCTAssertEqual(state.nick, "kerem")
    }

    func testDetectsAnonymous() throws {
        let state = try AuthParser.parse(html: try Fixture.html("auth-anonymous"))
        XCTAssertFalse(state.isLoggedIn)
        XCTAssertFalse(state.isIndeterminate)
        XCTAssertNil(state.nick)
    }

    /// Gündem isteğini `X-Requested-With` ile atıyoruz: gelen parça HTML'de
    /// üst menü yok. Böyle bir sayfa oturumun kapandığına kanıt değil.
    func testPartialPageIsIndeterminate() throws {
        let state = try AuthParser.parse(html: try Fixture.html("gundem"))
        XCTAssertTrue(state.isIndeterminate)
        XCTAssertFalse(state.isLoggedIn)
    }

    /// Entry yazarlarının profil bağlantısı da /biri/ ile başlıyor; üst menü
    /// dışındaki bağlantılara bakmıyoruz.
    func testEntryAuthorLinksDoNotCountAsLogin() throws {
        let state = try AuthParser.parse(html: try Fixture.html("topic"))
        XCTAssertFalse(state.isLoggedIn)
    }
}
