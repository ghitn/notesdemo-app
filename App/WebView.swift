import SwiftUI
import WebKit

/// SwiftUI wrapper around the WKWebView owned by WebViewModel
/// (the iOS counterpart of activity_main.xml's full-screen WebView).
struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
