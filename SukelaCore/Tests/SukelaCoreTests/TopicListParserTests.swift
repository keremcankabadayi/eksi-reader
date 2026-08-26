import XCTest
@testable import SukelaCore

final class TopicListParserTests: XCTestCase {
    func testParsesEveryTopic() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        XCTAssertEqual(topics.count, 4)
    }

    func testSeparatesTitleFromEntryCount() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        let first = try XCTUnwrap(topics.first)
        XCTAssertEqual(first.title, "kendi ekşi istemcini yazmak")
        XCTAssertEqual(first.entryCount, "142")
    }

    func testExtractsIdAndSlugFromLink() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        let first = try XCTUnwrap(topics.first)
        XCTAssertEqual(first.id, "123456")
        XCTAssertEqual(first.slug, "kendi-eksi-istemcini-yazmak")
        XCTAssertEqual(first.link, "/kendi-eksi-istemcini-yazmak--123456")
    }

    /// Ekşi büyük sayıları "1,2k" diye yazıyor; sayıya çevirmeye çalışmıyoruz.
    func testKeepsNonNumericEntryCountVerbatim() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        let topic = try XCTUnwrap(topics.first { $0.id == "555111" })
        XCTAssertEqual(topic.title, "26 ağustos 2026")
        XCTAssertEqual(topic.entryCount, "1,2k")
    }

    func testTopicWithoutEntryCountStillParses() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        let topic = try XCTUnwrap(topics.first { $0.id == "777" })
        XCTAssertEqual(topic.title, "entry sayısı olmayan başlık")
        XCTAssertEqual(topic.entryCount, "")
    }

    func testReturnsEmptyForUnrelatedHTML() throws {
        XCTAssertTrue(try TopicListParser.parse(html: "<html><body><p>yok</p></body></html>").isEmpty)
    }
}

// MARK: - Gerçek sayfada başlık listesiyle karışan içerikler

extension TopicListParserTests {
    /// Ekşi'nin entry listesinin sınıfı da "topic-list" ile başlıyor.
    /// Gevşek seçici entry'leri başlık sanıyordu.
    func testIgnoresEntryList() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        XCTAssertFalse(
            topics.contains { $0.title.contains("bu bir entry") },
            "Entry listesi başlık olarak ayrıştırıldı"
        )
        XCTAssertFalse(topics.contains { $0.link.hasPrefix("/entry/") })
    }

    /// Kanal/gezinme bağlantılarında "--id" deseni yok, başlık değiller.
    func testIgnoresNavigationLinks() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        XCTAssertFalse(topics.contains { $0.title == "spor" })
        XCTAssertFalse(topics.contains { $0.link.hasPrefix("/basliklar/kanal") })
    }

    func testParsesOnlyRealTopics() throws {
        let topics = try TopicListParser.parse(html: try Fixture.html("gundem"))
        XCTAssertEqual(topics.map(\.id), ["123456", "987", "555111", "777"])
    }
}
