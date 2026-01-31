import Combine
import Foundation
import WebKit

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    let nextStep: (AuthResponse?) -> Void
    
    init(nextStep: @escaping (AuthResponse?) -> Void, webView: WKWebView? = nil) {
        self.nextStep = nextStep
        self.webView = webView
    }

    weak var webView: WKWebView? {
        didSet {
            webView?.navigationDelegate = self
        }
    }


    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() {
            if scheme != "https", scheme != "http" {
                let code = url.absoluteString.components(separatedBy: "code=")[1]
                Task {
                    let tokenResponse = await AuthHttp.getToken(code: code)
                    nextStep(tokenResponse)
                }
                
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}
