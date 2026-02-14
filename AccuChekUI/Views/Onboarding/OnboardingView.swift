import LoopKitUI
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismissAction) private var dismiss
    let nextStep: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedString("Welcome!", comment: "welcome"))
                .font(.largeTitle)
                .bold()
            Text(LocalizedString(
                "When clicking Continue, you will scan for your Accu chek CGM. Make sure you have the PIN ready for pairing with your phone!",
                comment: "explain welcome"
            ))

            Spacer()
            Button(action: { nextStep() }) {
                Text("Continue")
            }
            .buttonStyle(ActionButtonStyle())
        }
        .padding(.horizontal)
        .edgesIgnoringSafeArea(.bottom)
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
