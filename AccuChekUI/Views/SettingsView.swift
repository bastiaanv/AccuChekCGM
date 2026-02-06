import LoopKitUI
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Text("DeviceName: \(viewModel.deviceName)")
        Text("Connected: \(viewModel.connected)")
        Button(action: { viewModel.deleteCGM() }) {
            Text("Delete CGM")
        }
        .buttonStyle(ActionButtonStyle())
    }
}
