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
            String(localized: "Found an Accu Chek CGM!", comment: "found device title"),
            isPresented: $viewModel.showConfirmationAlert,
            presenting: String(
                format: String(localized: "Is this the correct serial number? %@", comment: "found device message"),
                viewModel.foundDeviceLast?.deviceName ?? "EMPTY"
            ),
            actions: { _ in
                Button(action: { viewModel.startScanning() }) {
                    Text("No", comment: "label no")
                }
                Button(action: { if let device = viewModel.foundDeviceLast { viewModel.connect(result: device) } }) {
                    Text("Yes", comment: "label yes")
                }
            },
            message: { detail in Text(detail) }
        )
        .alert(
            String(localized: "Found unsupported Accu Chek CGM...", comment: "unsupported device title"),
            isPresented: $viewModel.showUnsupportedDeviceAlert,
            presenting: String(
                format: String(
                    localized:
                    "This Accu chek Sensor is using advanced encryption which is not supported yet... %@",
                    comment: "unsupported device message"
                ),
                viewModel.unsupportedDevice?.deviceName ?? "EMPTY"
            ),
            actions: { _ in
                Button(action: { viewModel.startScanning() }) {
                    Text("Understood", comment: "label undestood")
                }
            },
            message: { detail in Text(detail) }
        )
    }
}
