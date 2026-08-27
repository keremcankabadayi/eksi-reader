import XCTest
@testable import SukelaCore

final class TitleLayoutTests: XCTestCase {
    func testShortTitleStaysOnOneLine() {
        XCTAssertEqual(TitleLayout.twoLines("swiftui"), "swiftui")
    }

    func testBreaksAtLastSpaceBeforeLimit() {
        // "ligi" ile birlikte ilk satır 37 karakter olurdu, sınır 35.
        let title = "27 ağustos 2026 uefa şampiyonlar ligi kura çekimi"
        XCTAssertEqual(
            TitleLayout.twoLines(title),
            "27 ağustos 2026 uefa şampiyonlar\nligi kura çekimi"
        )
    }

    func testFirstLineNeverExceedsLimit() {
        let title = "bir iki üç dört beş altı yedi sekiz dokuz on"
        let first = TitleLayout.twoLines(title, limit: 20)
            .components(separatedBy: "\n")[0]
        XCTAssertLessThanOrEqual(first.count, 20)
        XCTAssertEqual(first, "bir iki üç dört beş")
    }

    func testSplitsMidWordWhenNoSpaceFits() {
        let title = String(repeating: "a", count: 50)
        let lines = TitleLayout.twoLines(title, limit: 35).components(separatedBy: "\n")
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines[0].count, 35)
        XCTAssertEqual(lines[1].count, 15)
    }

    func testTrimsSurroundingWhitespace() {
        XCTAssertEqual(TitleLayout.twoLines("  swiftui  "), "swiftui")
    }
}
