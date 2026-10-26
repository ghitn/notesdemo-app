import SwiftUI
import WebKit

/// Owns the WKWebView and plays the role of Android's WebViewClient + WebChromeClient.
final class WebViewModel: NSObject, ObservableObject {
    let webView: WKWebView
    let startURL: URL?

    @Published var isLoading = true
    @Published var errorText: String?

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true                // Android: mediaPlaybackRequiresUserGesture = false
        config.mediaTypesRequiringUserActionForPlayback = []
        config.websiteDataStore = .default()                   // Android: domStorageEnabled (persistent storage)

        webView = WKWebView(frame: .zero, configuration: config)
        startURL = AppConfig.startURL
        super.init()

        let background = UIColor(red: 6 / 255, green: 8 / 255, blue: 20 / 255, alpha: 1)
        webView.isOpaque = false
        webView.backgroundColor = background
        webView.scrollView.backgroundColor = background
        webView.allowsBackForwardNavigationGestures = true     // Android: onBackPressed -> goBack
        webView.navigationDelegate = self
        webView.uiDelegate = self
        #if DEBUG
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        #endif

        load()
    }

    func load() {
        errorText = nil
        guard let url = startURL else {
            isLoading = false
            errorText = "The start address in Info.plist is not a valid URL."
            return
        }
        isLoading = true
        webView.load(URLRequest(url: url))
    }

    func retry() {
        if webView.url != nil {
            errorText = nil
            isLoading = true
            webView.reload()
        } else {
            load()
        }
    }

    fileprivate func handle(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
        isLoading = false
        errorText = nsError.localizedDescription
    }

    fileprivate func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

// MARK: - Navigation

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        errorText = nil
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // mailto:, tel:, etc. go to the system; web pages stay in the app.
        if let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased(),
           !["http", "https", "about", "blob", "data", "file"].contains(scheme) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

// MARK: - UI (new windows, microphone, JavaScript dialogs)

extension WebViewModel: WKUIDelegate {
    // target="_blank" / window.open: open in the same view, like Android's default WebView behaviour.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    // Android: WebChromeClient.onPermissionRequest -> request.grant(...).
    // iOS still shows its own microphone prompt the first time (NSMicrophoneUsageDescription).
    // Only the app's own host is granted automatically; other origins get the system prompt.
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping (WKPermissionDecision) -> Void
    ) {
        decisionHandler(origin.host == startURL?.host ? .grant : .prompt)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        guard let presenter = topViewController() else { completionHandler(); return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let presenter = topViewController() else { completionHandler(false); return }
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        presenter.present(alert, animated: true)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let presenter = topViewController() else { completionHandler(nil); return }
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        presenter.present(alert, animated: true)
    }
}
