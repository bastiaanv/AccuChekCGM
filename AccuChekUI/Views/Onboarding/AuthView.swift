import LoopKitUI
import SwiftUI

struct AuthView: View {
    private let url = "https://access.rochedc.eu/oidc/authorize?prompt=login&apiKey=\(AuthHttp.API_KEY)&lang=en&country=nl&client_id=y5J-lVMkqyOI6cqTiJUb7EKp&redirect_uri=smartguide://oidc/success"
    let viewModel: WebViewModel
    
    var body: some View {
        WebViewWrapper(urlString: url, viewModel: viewModel)
    }
}
