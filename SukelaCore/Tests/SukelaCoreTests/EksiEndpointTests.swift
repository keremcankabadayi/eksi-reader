import XCTest
@testable import SukelaCore

final class EksiEndpointTests: XCTestCase {
    func testGundemFirstPageHasNoQuery() {
        XCTAssertEqual(
            EksiEndpoint.gundem().url?.absoluteString,
            "https://eksisozluk.com/basliklar/gundem"
        )
    }

    func testGundemLaterPageAddsQuery() {
        XCTAssertEqual(
            EksiEndpoint.gundem(page: 3).url?.absoluteString,
            "https://eksisozluk.com/basliklar/gundem?p=3"
        )
    }

    func testDebe() {
        XCTAssertEqual(EksiEndpoint.debe.url?.absoluteString, "https://eksisozluk.com/debe")
    }

    func testTopicUsesListLinkVerbatim() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/kendi-eksi-istemcini-yazmak--123456").url?.absoluteString,
            "https://eksisozluk.com/kendi-eksi-istemcini-yazmak--123456"
        )
    }

    /// Bağlantıda zaten sorgu varsa onu atıp kendi sayfa parametremizi koyuyoruz.
    func testTopicDropsExistingQuery() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?a=b", page: 2).url?.absoluteString,
            "https://eksisozluk.com/foo--1?p=2"
        )
    }
}
