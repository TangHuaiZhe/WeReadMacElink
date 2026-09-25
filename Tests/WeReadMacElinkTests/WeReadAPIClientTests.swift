import XCTest
@testable import WeReadMacElink

final class WeReadAPIClientTests: XCTestCase {
    func testRecentBooksAreUnfinishedAndSortedByLastReadTime() throws {
        let data = Data(
            """
            {"books":[
              {"bookId":"old","deepLink":"https://weread.qq.com/old","title":"旧书","author":"甲","readUpdateTime":100,"finishReading":0},
              {"bookId":"done","deepLink":"https://weread.qq.com/done","title":"读完","author":"乙","readUpdateTime":300,"finishReading":1},
              {"bookId":"new","deepLink":"https://weread.qq.com/new","title":"新书","author":"丙","readUpdateTime":200,"finishReading":0}
            ]}
            """.utf8
        )

        let books = try WeReadAPIClient.decodeRecentBooks(data: data)

        XCTAssertEqual(books.map(\.bookId), ["new", "old"])
    }

    func testSearchBooksFlattensGroupsAndRemovesDuplicates() throws {
        let data = Data(
            """
            {"results":[
              {"books":[{"bookInfo":{"bookId":"1","deepLink":"https://weread.qq.com/1","title":"三体","author":"刘慈欣","soldout":0}}]},
              {"books":[{"bookInfo":{"bookId":"1","deepLink":"https://weread.qq.com/1","title":"三体","author":"刘慈欣","soldout":0}},
                         {"bookInfo":{"bookId":"2","deepLink":"https://weread.qq.com/2","title":"球状闪电","author":"刘慈欣","soldout":1}}]}
            ]}
            """.utf8
        )

        let books = try WeReadAPIClient.decodeSearchBooks(data: data)

        XCTAssertEqual(books.map(\.bookId), ["1", "2"])
        XCTAssertTrue(books[1].soldout)
    }
}
