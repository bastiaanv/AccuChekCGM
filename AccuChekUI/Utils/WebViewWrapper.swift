import SwiftUI
import WebKit

struct WebViewWrapper: UIViewRepresentable {
    var urlString: String
    @ObservedObject var viewModel: WebViewModel

    func makeUIView(context _: Context) -> WKWebView {
        let webView = WKWebView()
        guard let url = URL(string: urlString) else {
            return webView
        }

        let request = URLRequest(url: url)
        viewModel.webView = webView
        webView.load(request)
        return webView
    }

    func updateUIView(_: WKWebView, context _: Context) {}
}
