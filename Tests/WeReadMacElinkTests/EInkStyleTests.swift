import XCTest
@testable import WeReadMacElink

final class EInkStyleTests: XCTestCase {
    func testProfileClampsUnsafeValues() {
        let profile = EInkProfile(textScale: 4, contrast: 0.2, contentWidth: 2)

        XCTAssertEqual(profile.textScale, 2)
        XCTAssertEqual(profile.contrast, 1)
        XCTAssertEqual(profile.contentWidth, 0.95)
    }

    func testStyleContainsReaderOverrides() {
        let css = EInkStyle.css(
            for: EInkProfile(
                textScale: 1.6,
                contrast: 1.5,
                contentWidth: 0.85,
                grayscale: true,
                reduceMotion: true
            )
        )

        XCTAssertTrue(css.contains(".readerChapterContent"))
        XCTAssertNil(
            css.range(
                of: #"(?s)\.readerChapterContent,\s*\.wr_horizontalReader \.readerChapterContent\s*\{[^}]*font-size:"#,
                options: .regularExpression
            )
        )
        XCTAssertTrue(css.contains("grayscale(100%) contrast(1.50)"))
        XCTAssertTrue(css.contains("color: #2b2b2b !important"))
        XCTAssertTrue(css.contains("-webkit-text-stroke: 0.30px currentColor"))
        XCTAssertTrue(css.contains("width: 85vw !important"))
        XCTAssertTrue(css.contains("height: 52px !important"))
        XCTAssertTrue(css.contains("padding-top: 72px !important"))
        XCTAssertTrue(css.contains("margin-left: clamp(24px, 3vw, 56px) !important"))
        XCTAssertTrue(css.contains("body:not(:has(.wr_horizontalReader)) .readerControls"))
        XCTAssertTrue(css.contains("right: max(16px, calc(3.75vw - 24px)) !important"))
        XCTAssertTrue(css.contains("::selection"))
        XCTAssertTrue(css.contains("background: #000000 !important"))
        XCTAssertTrue(css.contains("animation: none !important"))
    }

    func testCatalogPanelKeepsOfficialColorsInHorizontalReader() throws {
        let css = EInkStyle.css(for: EInkProfile())

        let inkRule = try XCTUnwrap(
            css.range(of: ".readerChapterContent :is(p, span, div, h1, h2, h3, h4, h5, h6, li, blockquote)")
        )
        let catalogRule = try XCTUnwrap(
            css.range(of: ".readerChapterContent .readerCatalog")
        )

        XCTAssertLessThan(inkRule.lowerBound, catalogRule.lowerBound)
        XCTAssertTrue(css.contains("color: #eef0f4 !important"))
        XCTAssertTrue(css.contains("-webkit-text-stroke: 0 transparent !important"))
    }

    func testColorModeCanKeepOriginalColors() {
        let css = EInkStyle.css(for: EInkProfile(grayscale: false))

        XCTAssertFalse(css.contains("grayscale(100%)"))
        XCTAssertTrue(css.contains("contrast(1.30)"))
    }

    func testPageTurnScriptsUseCurrentWereadPagerSelectors() {
        XCTAssertTrue(EInkStyle.pageTurnScript(direction: 1).contains("renderTarget_pager_button_right"))
        XCTAssertTrue(EInkStyle.pageTurnScript(direction: -1).contains(":not(.renderTarget_pager_button_right)"))
    }

    func testProgressTrackingUsesOfficialCatalogProgress() {
        let script = EInkStyle.progressTrackingScript

        XCTAssertTrue(script.contains(".readerCatalog"))
        XCTAssertTrue(script.contains("progressPercentage"))
        XCTAssertTrue(script.contains("当前读到"))
        XCTAssertTrue(script.contains("bookInfo?.bookId"))
        XCTAssertTrue(script.contains("@Id"))
        XCTAssertTrue(script.contains(EInkStyle.progressMessageHandler))
    }

    func testProgressTrackingReportsReaderLayout() {
        let script = EInkStyle.progressTrackingScript

        XCTAssertTrue(script.contains(".wr_horizontalReader"))
        XCTAssertTrue(script.contains(".readerContent"))
        XCTAssertTrue(script.contains("'horizontal'"))
        XCTAssertTrue(script.contains("'vertical'"))
        XCTAssertTrue(script.contains("bookId, layout"))
    }

}
