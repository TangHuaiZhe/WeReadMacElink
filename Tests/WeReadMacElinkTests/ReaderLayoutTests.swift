import XCTest
@testable import WeReadMacElink

final class ReaderLayoutTests: XCTestCase {
    func testMapsValuesReportedByThePage() {
        XCTAssertEqual(ReaderLayout(reportedValue: "vertical"), .verticalScrolling)
        XCTAssertEqual(ReaderLayout(reportedValue: "horizontal"), .horizontalPaging)
        XCTAssertEqual(ReaderLayout(reportedValue: nil), .unknown)
        XCTAssertEqual(ReaderLayout(reportedValue: ""), .unknown)
        XCTAssertEqual(ReaderLayout(reportedValue: "unexpected"), .unknown)
    }

    func testOnlyHorizontalPagingRendersTheArticleOnCanvas() {
        XCTAssertTrue(ReaderLayout.horizontalPaging.rendersArticleOnCanvas)
        XCTAssertFalse(ReaderLayout.verticalScrolling.rendersArticleOnCanvas)
        XCTAssertFalse(ReaderLayout.unknown.rendersArticleOnCanvas)
    }
}
