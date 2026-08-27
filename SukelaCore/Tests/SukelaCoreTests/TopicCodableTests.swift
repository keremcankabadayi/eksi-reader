import XCTest
@testable import SukelaCore

/// Başlık listesi diske yazılıp açılışta geri okunuyor; alanların gidip
/// geldiğini burada sabitliyoruz.
final class TopicCodableTests: XCTestCase {
    func testRoundTripKeepsEveryField() throws {
        let topics = [
            Topic(
                id: "/kendi-eksi-istemcini-yazmak--123",
                title: "kendi ekşi istemcini yazmak",
                slug: "kendi-eksi-istemcini-yazmak",
                entryCount: "1,2k",
                link: "/kendi-eksi-istemcini-yazmak--123"
            ),
            Topic(id: "/sideloading--9", title: "sideloading", slug: "sideloading", entryCount: "", link: "/sideloading--9"),
        ]

        let data = try JSONEncoder().encode(topics)
        let decoded = try JSONDecoder().decode([Topic].self, from: data)

        XCTAssertEqual(decoded, topics)
        XCTAssertEqual(decoded.first?.entryCount, "1,2k")
    }
}
