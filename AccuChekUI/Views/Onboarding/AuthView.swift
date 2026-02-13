import LoopKitUI
import SwiftUI
import WebKit

struct AuthView: View {
    private let url =
        "https://access.rochedc.eu/oidc/authorize?prompt=login&apiKey=\(AuthHttp.API_KEY)&lang=en&country=nl&client_id=y5J-lVMkqyOI6cqTiJUb7EKp&redirect_uri=smartguide://oidc/success"
    let viewModel: WebViewModel

    var body: some View {
        WebViewWrapper(urlString: url, viewModel: viewModel)
    }
}

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
