import XCTest
@testable import SukelaCore

final class TopicPageTests: XCTestCase {
    private func page(currentPage: Int, pageCount: Int = 30) -> TopicPage {
        TopicPage(
            title: "başlık",
            slug: "baslik",
            topicId: "1",
            entries: [],
            currentPage: currentPage,
            pageCount: pageCount
        )
    }

    func testFirstPageHasNoPrecedingEntries() {
        XCTAssertEqual(page(currentPage: 1).precedingEntryCount, 0)
        XCTAssertNil(page(currentPage: 1).previousPage)
    }

    func testPrecedingEntryCountCountsWholePages() {
        // Sayfa 22'den açılıyorsa üstte 21 sayfalık, yani 210 entry kalıyor.
        XCTAssertEqual(page(currentPage: 22).precedingEntryCount, 210)
        XCTAssertEqual(page(currentPage: 22).previousPage, 21)
    }

    func testBogusPageNumberDoesNotProduceNegativeCount() {
        XCTAssertEqual(page(currentPage: 0).precedingEntryCount, 0)
        XCTAssertNil(page(currentPage: 0).previousPage)
    }
}
