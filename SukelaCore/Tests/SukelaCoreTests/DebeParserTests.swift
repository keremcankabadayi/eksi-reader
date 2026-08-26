import XCTest
@testable import SukelaCore

final class DebeParserTests: XCTestCase {
    func testParsesEveryDebeEntry() throws {
        let items = try DebeParser.parse(html: try Fixture.html("debe"))
        XCTAssertEqual(items.count, 3)
    }

    /// Başlık `span.caption` içinde; yoksa bağlantının kendi metni.
    func testUsesCaptionAsTitle() throws {
        let items = try DebeParser.parse(html: try Fixture.html("debe"))
        XCTAssertEqual(items[0].title, "kendi ekşi istemcini yazmak")
        XCTAssertEqual(items[2].title, "caption'sız başlık")
    }

    /// Kimlik entry id'si; bağlantı entry kalıcı bağlantısı.
    func testExtractsEntryId() throws {
        let items = try DebeParser.parse(html: try Fixture.html("debe"))
        XCTAssertEqual(items[0].id, "98765")
        XCTAssertEqual(items[0].link, "/entry/98765?debe=true")
    }

    func testIgnoresNavigationLinks() throws {
        let items = try DebeParser.parse(html: try Fixture.html("debe"))
        XCTAssertFalse(items.contains { $0.title == "spor" })
    }

    func testReturnsEmptyForUnrelatedHTML() throws {
        XCTAssertTrue(try DebeParser.parse(html: "<html><body><p>yok</p></body></html>").isEmpty)
    }

    /// DEBE bağlantıları "--id" deseni taşımıyor; başlık listesi ayrıştırıcısı
    /// bunları kasten eliyor, o yüzden ayrı bir ayrıştırıcı gerekiyor.
    func testTopicListParserRejectsDebeLinks() throws {
        XCTAssertTrue(try TopicListParser.parse(html: try Fixture.html("debe")).isEmpty)
    }
}
