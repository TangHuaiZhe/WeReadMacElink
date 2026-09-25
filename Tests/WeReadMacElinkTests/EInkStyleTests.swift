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
        XCTAssertFalse(css.contains("font-size:"))
        XCTAssertTrue(css.contains("grayscale(100%) contrast(1.50)"))
        XCTAssertTrue(css.contains("color: #2b2b2b !important"))
        XCTAssertTrue(css.contains("-webkit-text-stroke: 0.30px currentColor"))
        XCTAssertTrue(css.contains("width: 85vw !important"))
        XCTAssertTrue(css.contains("margin-left: clamp(24px, 3vw, 56px) !important"))
        XCTAssertTrue(css.contains("::selection"))
        XCTAssertTrue(css.contains("background: #000000 !important"))
        XCTAssertTrue(css.contains("animation: none !important"))
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
}
