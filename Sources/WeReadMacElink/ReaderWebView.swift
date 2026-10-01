import AppKit
import SwiftUI
import WebKit

struct ReaderWebView: NSViewRepresentable {
    @ObservedObject var settings: ReaderSettings
    @ObservedObject var navigator: ReaderNavigator
    @Binding var screenName: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.isElementFullscreenEnabled = true
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: EInkStyle.installationScript(for: settings.profile),
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController.addUserScript(
            WKUserScript(
                source: EInkStyle.progressTrackingScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )
        configuration.userContentController.add(
            context.coordinator,
            name: EInkStyle.progressMessageHandler
        )

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsMagnification = true
        webView.pageZoom = settings.profile.textScale
        webView.setValue(false, forKey: "drawsBackground")
        navigator.webView = webView

        webView.load(URLRequest(url: URL(string: "https://weread.qq.com/")!))
        DispatchQueue.main.async {
            context.coordinator.updateScreenName(for: webView)
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.parent = self
        navigator.webView = webView
        webView.pageZoom = settings.profile.textScale
        webView.evaluateJavaScript(EInkStyle.installationScript(for: settings.profile))
        webView.evaluateJavaScript(EInkStyle.progressTrackingScript)
        context.coordinator.updateScreenName(for: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: ReaderWebView

        init(_ parent: ReaderWebView) {
            self.parent = parent
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(windowDidChangeScreen(_:)),
                name: NSWindow.didChangeScreenNotification,
                object: nil
            )
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.pageZoom = parent.settings.profile.textScale
            webView.evaluateJavaScript(EInkStyle.installationScript(for: parent.settings.profile))
            webView.evaluateJavaScript(EInkStyle.progressTrackingScript)
            updateScreenName(for: webView)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            let host = message.frameInfo.securityOrigin.host.lowercased()
            guard host == "weread.qq.com" || host.hasSuffix(".weread.qq.com") else { return }
            guard let payload = message.body as? [String: Any] else { return }
            if message.name == EInkStyle.progressMessageHandler,
               let value = payload["progress"] as? NSNumber {
                let progress = value.intValue
                parent.navigator.updateReadingContext(
                    progress: progress >= 0 ? progress : nil,
                    bookId: payload["bookId"] as? String,
                    layout: ReaderLayout(reportedValue: payload["layout"] as? String)
                )
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard navigationAction.targetFrame?.isMainFrame != false,
                  let url = navigationAction.request.url,
                  let host = url.host?.lowercased()
            else {
                decisionHandler(.allow)
                return
            }

            if host == "weread.qq.com" || host.hasSuffix(".weread.qq.com") {
                decisionHandler(.allow)
            } else {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            if url.host == "weread.qq.com" || url.host?.hasSuffix(".weread.qq.com") == true {
                webView.load(URLRequest(url: url))
            } else {
                NSWorkspace.shared.open(url)
            }
            return nil
        }

        func updateScreenName(for webView: WKWebView) {
            guard let name = webView.window?.screen?.localizedName,
                  name != parent.screenName
            else { return }
            DispatchQueue.main.async {
                self.parent.screenName = name
            }
        }

        @objc private func windowDidChangeScreen(_ notification: Notification) {
            guard let webView = parent.navigator.webView,
                  let changedWindow = notification.object as? NSWindow,
                  changedWindow === webView.window
            else { return }
            updateScreenName(for: webView)
        }
    }
}
