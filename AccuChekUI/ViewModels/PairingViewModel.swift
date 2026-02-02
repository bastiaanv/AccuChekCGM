import Combine
import LoopKit
import SwiftUI

class PairingViewModel: ObservableObject {
    private let logger = AccuChekLogger(category: "PairingViewModel")

    private let cgmManager: AccuChekCgmManager?
    init(_ cgmManager: AccuChekCgmManager?, deleteCGM _: @escaping () -> Void) {
        self.cgmManager = cgmManager
    }

    func startScanning() {
        guard let cgmManager else {
            logger.error("No CGM manager to start scanning")
            return
        }

        cgmManager.bluetooth.startScan { result in
            cgmManager.state.serialNumber = result.deviceName
            cgmManager.state.hasAcs = result.hasAcsSupport
            cgmManager.notifyStateDidChange()

            cgmManager.bluetooth.connect(to: result.peripheral) { error in
                if let error {
                    self.logger.error("Failed to connect to CGM: \(error)")
                    return
                }
            }
        }
    }
}
