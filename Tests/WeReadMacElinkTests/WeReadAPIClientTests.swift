import XCTest
@testable import WeReadMacElink

final class WeReadAPIClientTests: XCTestCase {
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
