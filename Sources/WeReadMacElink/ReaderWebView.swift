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
        context.coordinator.updateScreenName(for: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
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
            updateScreenName(for: webView)
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
