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

    // MARK: - Bağlantının kendi sorgusu

    /// Ekşi, daha önce açtığın başlık için "nereden devam edeceğin" bilgisini
    /// gündem bağlantısının sorgusunda veriyor. Atarsak başlık hep baştan açılır.
    func testKeepsLinkQueryWhenNoPageGiven() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?a=popular").url?.absoluteString,
            "https://eksisozluk.com/foo--1?a=popular"
        )
    }

    func testKeepsPageFromLink() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?p=5").url?.absoluteString,
            "https://eksisozluk.com/foo--1?p=5"
        )
    }

    func testKeepsEveryLinkParameter() {
        let url = EksiEndpoint.topic(link: "/foo--1?a=popular&day=2026-08-26").url?.absoluteString
        XCTAssertEqual(url, "https://eksisozluk.com/foo--1?a=popular&day=2026-08-26")
    }

    // MARK: - Sayfa açıkça verilince

    /// Sayfayı biz belirlediğimizde bağlantıdaki p değişiyor, kip (a=popular)
    /// olduğu gibi kalıyor: kip başlığın kaç sayfa olduğunu belirliyor.
    func testExplicitPageReplacesLinkPage() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?a=popular&p=5", page: 2).url?.absoluteString,
            "https://eksisozluk.com/foo--1?a=popular&p=2"
        )
    }

    /// Birinci sayfada da `p` yazılıyor: `p` olmadan Ekşi `a=popular`/`focusto`
    /// bağlantısını okunmamış entry'nin sayfasına yönlendiriyor, "önceki
    /// entry'ler" hep aynı sayfayı getiriyordu.
    func testExplicitFirstPageIsWritten() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?p=5", page: 1).url?.absoluteString,
            "https://eksisozluk.com/foo--1?p=1"
        )
    }

    func testExplicitPageDropsPositionParameters() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?focusto=185944547", page: 3).url?.absoluteString,
            "https://eksisozluk.com/foo--1?p=3"
        )
    }

    func testExplicitPageKeepsOtherParameters() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?day=2026-08-26&a=popular", page: 4).url?.absoluteString,
            "https://eksisozluk.com/foo--1?day=2026-08-26&a=popular&p=4"
        )
    }

    /// focusto sayfa numarasıyla çelişiyor, o düşüyor.
    func testExplicitPageDropsFocusButKeepsMode() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1?a=popular&focusto=99", page: 2).url?.absoluteString,
            "https://eksisozluk.com/foo--1?a=popular&p=2"
        )
    }

    func testExplicitPageOnPlainLink() {
        XCTAssertEqual(
            EksiEndpoint.topic(link: "/foo--1", page: 3).url?.absoluteString,
            "https://eksisozluk.com/foo--1?p=3"
        )
    }

    /// Favorileme uçları sitenin kendi JS'indeki adlarla.
    func testFavoriteEndpoints() {
        XCTAssertEqual(
            EksiEndpoint.addFavorite.url?.absoluteString,
            "https://eksisozluk.com/entry/favla"
        )
        XCTAssertEqual(
            EksiEndpoint.removeFavorite.url?.absoluteString,
            "https://eksisozluk.com/entry/favlama"
        )
    }
}
