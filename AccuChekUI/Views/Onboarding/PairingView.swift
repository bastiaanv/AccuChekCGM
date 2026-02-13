import LoopKitUI
import SwiftUI

struct PairingView: View {
    @ObservedObject var viewModel: PairingViewModel

    var body: some View {
        VStack {
            Text(viewModel.state.text)
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
        }
        .alert(
            LocalizedString("Found Accu Chek CGM!", comment: "found device message"),
            isPresented: $viewModel.showConfirmationAlert,
            presenting: "Is this the correct serial number? \(viewModel.foundDeviceLast?.deviceName ?? "EMPTY")",
            actions: { _ in
                Button(LocalizedString("No", comment: "label no"), action: {
                    viewModel.startScanning()
                })
                Button(LocalizedString("Yes", comment: "label yes"), action: {
                    if let device = viewModel.foundDeviceLast {
                        viewModel.connect(result: device)
                    }
                })
            },
            message: { detail in Text(detail) }
        )
    }
}
