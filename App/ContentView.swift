import SwiftUI

struct ContentView: View {
    @StateObject private var model = WebViewModel()

    private let background = Color(red: 6 / 255, green: 8 / 255, blue: 20 / 255)

    var body: some View {
        ZStack {
            // Same dark colour as the page, so no white flash and no gap around the web view.
            background.ignoresSafeArea()

            // Not ignoring the safe area keeps the page below the status bar,
            // like the Android app (and the keyboard resizes it, like adjustResize).
            WebView(webView: model.webView)

            if model.isLoading && model.errorText == nil {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
                    .scaleEffect(1.3)
            }

            if let message = model.errorText {
                ErrorView(message: message, url: model.startURL) {
                    model.retry()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct ErrorView: View {
    let message: String
    let url: URL?
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.85))

            Text("Can't reach the notes service")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.white.opacity(0.7))

            if let url {
                Text(url.absoluteString)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.5))
            }

            Button(action: onRetry) {
                Text("Try again")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.18)))
                    .foregroundColor(.white)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 6 / 255, green: 8 / 255, blue: 20 / 255))
    }
}
