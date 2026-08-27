import XCTest
@testable import SukelaCore

final class WidgetStoreTests: XCTestCase {
    private func topic(_ index: Int) -> Topic {
        Topic(
            id: "\(index)",
            title: "başlık \(index)",
            slug: "baslik-\(index)",
            entryCount: "\(index * 3)",
            link: "/baslik-\(index)--\(index)"
        )
    }

    func testSnapshotCarriesTitleCountAndLink() {
        let snapshot = WidgetStore.snapshot(from: [topic(1)], at: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(snapshot.topics.first?.title, "başlık 1")
        XCTAssertEqual(snapshot.topics.first?.entryCount, "3")
        XCTAssertEqual(snapshot.topics.first?.link, "/baslik-1--1")
    }

    /// Widget dar; listeyi olduğu gibi taşımıyoruz.
    func testSnapshotIsCapped() {
        let topics = (1...50).map(topic)
        let snapshot = WidgetStore.snapshot(from: topics, at: Date())
        XCTAssertEqual(snapshot.topics.count, WidgetStore.topicLimit)
    }

    func testRoundTripThroughFile() throws {
        let container = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: container) }

        let written = WidgetStore.snapshot(
            from: [topic(1), topic(2)],
            at: Date(timeIntervalSince1970: 1_756_000_000)
        )
        try WidgetStore.write(written, to: container)
        let read = try WidgetStore.read(from: container)

        XCTAssertEqual(read, written)
    }

    func testReadingMissingFileThrows() {
        let container = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        XCTAssertThrowsError(try WidgetStore.read(from: container))
    }
}

final class DeepLinkTests: XCTestCase {
    func testRoundTrip() throws {
        let link = DeepLink.topic(link: "/baslik--1?a=popular", title: "başlık")
        let url = try XCTUnwrap(link.url)
        XCTAssertEqual(url.scheme, "sukela")
        XCTAssertEqual(DeepLink.parse(url), link)
    }

    func testRejectsForeignScheme() throws {
        let url = try XCTUnwrap(URL(string: "https://eksisozluk.com/baslik--1"))
        XCTAssertNil(DeepLink.parse(url))
    }

    func testRejectsMissingLink() throws {
        let url = try XCTUnwrap(URL(string: "sukela://topic?title=bos"))
        XCTAssertNil(DeepLink.parse(url))
    }

    func testTitleIsOptional() throws {
        let url = try XCTUnwrap(URL(string: "sukela://topic?link=/baslik--1"))
        XCTAssertEqual(DeepLink.parse(url), .topic(link: "/baslik--1", title: ""))
    }
}

final class SessionSnapshotTests: XCTestCase {
    private func snapshot(expiring: Date?) -> SessionSnapshot {
        SessionSnapshot(
            userAgent: "Mozilla/5.0 (iPhone)",
            cookies: [
                SessionCookie(
                    name: "cf_clearance", value: "abc",
                    domain: ".eksisozluk.com", path: "/", expiresAt: expiring
                ),
                SessionCookie(
                    name: "a", value: "1",
                    domain: ".eksisozluk.com", path: "/", expiresAt: nil
                ),
            ],
            updatedAt: Date(timeIntervalSince1970: 0)
        )
    }

    func testCookieHeaderJoinsPairs() {
        XCTAssertEqual(snapshot(expiring: nil).cookieHeader(), "cf_clearance=abc; a=1")
    }

    /// Süresi geçmiş çerezi göndermenin anlamı yok; Cloudflare zaten reddediyor.
    func testCookieHeaderDropsExpired() {
        let past = Date(timeIntervalSince1970: 1_000)
        let header = snapshot(expiring: past).cookieHeader(at: Date(timeIntervalSince1970: 2_000))
        XCTAssertEqual(header, "a=1")
    }

    func testDetectsClearanceCookie() {
        XCTAssertTrue(snapshot(expiring: nil).hasClearance)
    }

    func testRoundTripThroughFile() throws {
        let container = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: container) }

        let written = snapshot(expiring: Date(timeIntervalSince1970: 9_999_999))
        try SessionStore.write(written, to: container)
        XCTAssertEqual(try SessionStore.read(from: container), written)
    }
}
