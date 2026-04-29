import LoopKitUI
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismissAction) private var dismiss
    let manualScan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(
                "Before starting, double check if your Accu-chek CGM is not expired. Expired CGM's cannot be used",
                comment: "explain welcome"
            )
            Text(
                "When clicking Continue, you will scan for your Accu chek CGM. Make sure you have the PIN ready for pairing with your phone!",
                comment: "explain welcome"
            )

            Spacer()
            Button(action: manualScan) {
                Text("Continue", comment: "label continue")
            }
            .buttonStyle(ActionButtonStyle())
        }
        .padding(.horizontal)
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle(String(localized: "Welcome!", comment: "welcome"))
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: self.dismiss) {
                    Text("Cancel", comment: "Cancel button title")
                }
            }
        }
    }
}
