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

    func testDecodeReadingStatisticsUsesTodayBucketAndPeriodTotals() throws {
        let weeklyData = Data(
            """
            {"baseTime":1790524800,"totalReadTime":9000,"readTimes":{"1790524800":4612}}
            """.utf8
        )
        let annualData = Data(
            """
            {"baseTime":1767196800,"totalReadTime":559222}
            """.utf8
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        let now = Date(timeIntervalSince1970: 1_790_568_000)

        let statistics = try WeReadAPIClient.decodeReadingStatistics(
            weeklyData: weeklyData,
            annualData: annualData,
            now: now,
            calendar: calendar
        )

        XCTAssertEqual(statistics, WeReadReadingStatistics(today: 4612, week: 9000, year: 559222))
    }

    func testReadingDurationTextUsesMinutesAndHours() {
        XCTAssertEqual(WeReadReadingStatistics.durationText(seconds: 59), "0 分钟")
        XCTAssertEqual(WeReadReadingStatistics.durationText(seconds: 3_600), "1 小时")
        XCTAssertEqual(WeReadReadingStatistics.durationText(seconds: 3_661), "1 小时 1 分")
    }
}
