import LoopKitUI
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismissAction) private var dismiss
    let manualScan: () -> Void
    let qrScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedString(
                "When clicking Continue, you will scan for your Accu chek CGM. Make sure you have the PIN ready for pairing with your phone!",
                comment: "explain welcome"
            ))
            Text(LocalizedString(
                "If you have an expired Accu-chek, make sure to scan the QR-code in order to bypass the expiration check",
                comment: "explain welcome"
            ))

            Spacer()
            Button(action: { qrScan() }) {
                Text("Scan QR-code")
            }
            .buttonStyle(ActionButtonStyle())
            Button(action: { manualScan() }) {
                Text("Manual scan mode")
            }
            .buttonStyle(ActionButtonStyle(.secondary))
        }
        .padding(.horizontal)
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle(LocalizedString("Welcome!", comment: "welcome"))
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(LocalizedString("Cancel", comment: "Cancel button title"), action: {
                    self.dismiss()
                })
            }
        }
    }
}
