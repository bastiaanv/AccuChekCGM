import LoopKitUI
import SwiftUI

struct OnboardingView: View {
    let nextStep: () -> Void

    var body: some View {
        Button(action: { nextStep() }) {
            Text("Continue")
        }
        .buttonStyle(ActionButtonStyle())
    }
}
