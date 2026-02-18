import LoopKitUI
import SwiftUI

struct PairingView: View {
    @ObservedObject var viewModel: PairingViewModel

    var body: some View {
        VStack {
            Text(viewModel.state.text)
                .foregroundStyle(.primary)
            Text(viewModel.state.desciption)
                .foregroundStyle(.secondary)
            ActivityIndicator(isAnimating: .constant(true), style: .medium)
        }
        .alert(
            LocalizedString("Found an Accu Chek CGM!", comment: "found device title"),
            isPresented: $viewModel.showConfirmationAlert,
            presenting: String(
                format: LocalizedString("Is this the correct serial number? %@", comment: "found device message"),
                viewModel.foundDeviceLast?.deviceName ?? "EMPTY"
            ),
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
        .alert(
            LocalizedString("Found unsupported Accu Chek CGM...", comment: "unsupported device title"),
            isPresented: $viewModel.showUnsupportedDeviceAlert,
            presenting: String(
                format: LocalizedString(
                    "This Accu chek Sensor is using advanced encryption which is not supported yet... %@",
                    comment: "unsupported device message"
                ),
                viewModel.unsupportedDevice?.deviceName ?? "EMPTY"
            ),
            actions: { _ in
                Button(LocalizedString("Understood", comment: "label undestood"), action: {
                    viewModel.startScanning()
                })
            },
            message: { detail in Text(detail) }
        )
    }
}
