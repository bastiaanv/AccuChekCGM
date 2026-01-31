import Combine
import LoopKit
import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var connected: Bool

    private let cgmManager: AccuChekCgmManager?
    let deleteCGM: () -> Void
    init(_ cgmManager: AccuChekCgmManager?, deleteCGM: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.deleteCGM = deleteCGM
        connected = false

        cgmManager?.addStateObserver(state: self, queue: DispatchQueue.main)
    }
}

extension SettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: AccuChekState) {
        DispatchQueue.main.async {
            self.connected = state.isConnected
        }
    }
}
