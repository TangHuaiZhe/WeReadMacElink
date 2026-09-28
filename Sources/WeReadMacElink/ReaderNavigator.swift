import AppKit
import Combine
import WebKit

@MainActor
final class ReaderNavigator: ObservableObject {
    weak var webView: WKWebView?
    @Published private(set) var readingProgress: Int?

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

    func updateReadingProgress(_ progress: Int?) {
        readingProgress = progress
    }
}
