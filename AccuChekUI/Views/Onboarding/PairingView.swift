import LoopKitUI
import SwiftUI

struct PairingView: View {
    @ObservedObject var viewModel: PairingViewModel

    var body: some View {
        Text(LocalizedString("Pairing with CGM", comment: ""))
        ActivityIndicator(isAnimating: .constant(true), style: .medium)
    }
}
