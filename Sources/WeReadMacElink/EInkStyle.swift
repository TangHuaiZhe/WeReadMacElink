import Foundation

enum EInkStyle {
    static let styleElementID = "weread-mac-elink-style"

    static func css(for profile: EInkProfile) -> String {
        let contrast = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), profile.contrast)
        let normalizedContrast = ((profile.contrast - 1) / 1).clamped(to: 0...1)
        let inkLevel = Int(normalizedContrast * 85)
        let inkChannel = 85 - inkLevel
        let inkColor = String(format: "#%02x%02x%02x", inkChannel, inkChannel, inkChannel)
        let strokeWidth = String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            normalizedContrast * 0.6
        )
        let contentWidth = Int((profile.contentWidth * 100).rounded())
        let controlsGutter = String(
            format: "%.2f",
            locale: Locale(identifier: "en_US_POSIX"),
            (100 - Double(contentWidth)) / 4
        )
        let filter = profile.grayscale
            ? "grayscale(100%) contrast(\(contrast))"
            : "contrast(\(contrast))"
        let motionRule = profile.reduceMotion
            ? "* { animation: none !important; transition: none !important; scroll-behavior: auto !important; }"
            : ""

        return """
        :root {
          color-scheme: light !important;
          filter: \(filter) !important;
        }
        html, body, #app, .wr_page_reader, .readerChapterContent_container {
          background: #ffffff !important;
        }
        .readerContent .app_content {
          width: \(contentWidth)vw !important;
          max-width: \(contentWidth)vw !important;
          margin-left: auto !important;
          margin-right: auto !important;
        }
        .readerContent .readerTopBar,
        .readerContent .navBar_inner {
          width: \(contentWidth)vw !important;
          max-width: \(contentWidth)vw !important;
        }
        .readerContent .readerChapterContent,
        .readerContent .readerContentHeader {
          margin-left: clamp(24px, 3vw, 56px) !important;
          margin-right: clamp(24px, 3vw, 56px) !important;
        }
        body:not(:has(.wr_horizontalReader)) .readerControls {
          left: auto !important;
          right: max(16px, calc(\(controlsGutter)vw - 24px)) !important;
          margin-left: 0 !important;
        }
        .readerChapterContent,
        .wr_horizontalReader .readerChapterContent {
          color: \(inkColor) !important;
          background: #ffffff !important;
          box-shadow: none !important;
        }
        .readerChapterContent :is(p, span, div, h1, h2, h3, h4, h5, h6, li, blockquote) {
          color: inherit !important;
          -webkit-text-stroke: \(strokeWidth)px currentColor;
          text-shadow: none !important;
        }
        ::selection {
          color: #ffffff !important;
          -webkit-text-fill-color: #ffffff !important;
          -webkit-text-stroke: 0 transparent !important;
          background: #000000 !important;
          text-shadow: none !important;
        }
        \(motionRule)
        """
    }

    static func installationScript(for profile: EInkProfile) -> String {
        let encodedCSS = javascriptStringLiteral(css(for: profile))
        return """
        (() => {
          const id = '\(styleElementID)';
          let style = document.getElementById(id);
          if (!style) {
            style = document.createElement('style');
            style.id = id;
            (document.head || document.documentElement).appendChild(style);
          }
          style.textContent = \(encodedCSS);
        })();
        """
    }

    static func pageTurnScript(direction: Int) -> String {
        let isNext = direction >= 0
        let selector = isNext
            ? ".renderTarget_pager_button_right"
            : ".renderTarget_pager_button:not(.renderTarget_pager_button_right)"
        let key = isNext ? "ArrowRight" : "ArrowLeft"
        let amount = isNext ? "0.88" : "-0.88"

        return """
        (() => {
          const button = document.querySelector('\(selector)');
          if (button) {
            button.click();
            return 'button';
          }
          document.dispatchEvent(new KeyboardEvent('keydown', { key: '\(key)', bubbles: true }));
          window.scrollBy({ top: window.innerHeight * \(amount), behavior: 'auto' });
          return 'fallback';
        })();
        """
    }

    private static func javascriptStringLiteral(_ value: String) -> String {
        let data = try! JSONSerialization.data(withJSONObject: [value])
        let arrayLiteral = String(decoding: data, as: UTF8.self)
        return String(arrayLiteral.dropFirst().dropLast())
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
