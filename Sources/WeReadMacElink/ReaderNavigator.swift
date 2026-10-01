import AppKit
import Combine
import WebKit

/// 微信读书阅读页当前使用的排版布局。后两者互斥，由站点服务端配置决定。
enum ReaderLayout: Equatable {
    /// 不在阅读页，或还没读到布局信息。
    case unknown
    /// 上下滚动模式（`.readerContent`），正文字是普通 DOM。
    case verticalScrolling
    /// 双栏横向翻页模式（`.wr_horizontalReader`），正文被预渲染到画布。
    case horizontalPaging

    init(reportedValue: String?) {
        switch reportedValue {
        case "vertical":
            self = .verticalScrolling
        case "horizontal":
            self = .horizontalPaging
        default:
            self = .unknown
        }
    }

    /// 双栏模式把正文预渲染进画布，CSS 无法影响正文文字：
    /// 正文宽度和文字墨色、笔画调整都拿不到正文，只有页面缩放和整页 filter 仍然有效。
    var rendersArticleOnCanvas: Bool {
        self == .horizontalPaging
    }
}

@MainActor
final class ReaderNavigator: ObservableObject {
    weak var webView: WKWebView?
    @Published private(set) var readingProgress: Int?
    @Published private(set) var currentBookId: String?
    @Published private(set) var readerLayout: ReaderLayout = .unknown

    func goHome() {
        webView?.load(URLRequest(url: URL(string: "https://weread.qq.com/")!))
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func open(_ url: URL) {
        webView?.load(URLRequest(url: url))
    }

    func previousPage() {
        webView?.evaluateJavaScript(EInkStyle.pageTurnScript(direction: -1))
    }

    func nextPage() {
        webView?.evaluateJavaScript(EInkStyle.pageTurnScript(direction: 1))
    }

    func updateReadingContext(progress: Int?, bookId: String?, layout: ReaderLayout) {
        readingProgress = progress
        currentBookId = bookId
        readerLayout = layout
    }
}
