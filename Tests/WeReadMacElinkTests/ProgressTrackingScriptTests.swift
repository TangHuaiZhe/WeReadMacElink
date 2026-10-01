import JavaScriptCore
import XCTest
@testable import WeReadMacElink

/// 在 JavaScriptCore 的桩 DOM 上真实执行注入脚本，验证它上报的布局、进度与书籍 ID。
final class ProgressTrackingScriptTests: XCTestCase {
    private func postedMessages(path: String, selectors: String) throws -> [[String: Any]] {
        let context = try XCTUnwrap(JSContext())
        let prelude = """
        var __posted = [];
        var __selectors = {};
        \(selectors)
        var window = {
          webkit: { messageHandlers: { readingProgress: { postMessage: function (message) { __posted.push(message); } } } },
          setInterval: function () {},
          addEventListener: function () {}
        };
        var location = { pathname: '\(path)' };
        var document = {
          documentElement: {},
          querySelector: function (selector) { return __selectors[selector] || null; }
        };
        function MutationObserver(callback) { this.observe = function () {}; }
        """
        context.evaluateScript(prelude)

        context.evaluateScript(EInkStyle.progressTrackingScript)
        if let exception = context.exception {
            XCTFail("注入脚本抛出异常：\(exception)")
        }

        let json = try XCTUnwrap(context.evaluateScript("JSON.stringify(__posted)")?.toString())
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])
    }

    func testHorizontalReaderReportsCanvasLayoutAndVueProgress() throws {
        let messages = try postedMessages(
            path: "/web/reader/abc",
            selectors: """
            __selectors['.wr_horizontalReader'] = {};
            __selectors['.readerCatalog'] = {
              textContent: '目录',
              __vue__: { progressPercentage: 42, bookInfo: { bookId: 'book-1' } }
            };
            """
        )

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(message["layout"] as? String, "horizontal")
        XCTAssertEqual(message["progress"] as? Int, 42)
        XCTAssertEqual(message["bookId"] as? String, "book-1")
    }

    func testVerticalReaderFallsBackToCatalogTextAndStructuredMetadata() throws {
        let messages = try postedMessages(
            path: "/web/reader/xyz",
            selectors: """
            __selectors['.readerContent'] = {};
            __selectors['.readerCatalog'] = { textContent: '第一章 当前读到 37.5% 完' };
            __selectors['script[type="application/ld+json"]'] = { textContent: '{"@Id":"33628204"}' };
            """
        )

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(message["layout"] as? String, "vertical")
        XCTAssertEqual(message["progress"] as? Int, 38)
        XCTAssertEqual(message["bookId"] as? String, "33628204")
    }

    func testPageOutsideTheReaderReportsNoLayoutAndNoProgress() throws {
        let messages = try postedMessages(path: "/web/store", selectors: "")

        let message = try XCTUnwrap(messages.first)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(message["progress"] as? Int, -1)
        XCTAssertTrue(message["layout"] is NSNull)
        XCTAssertTrue(message["bookId"] is NSNull)
    }
}
