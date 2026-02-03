import Combine
import LoopKit
import SwiftUI

class PairingViewModel: ObservableObject {
    private let logger = AccuChekLogger(category: "PairingViewModel")

    private let cgmManager: AccuChekCgmManager?
    init(_ cgmManager: AccuChekCgmManager?) {
        self.cgmManager = cgmManager

        fetchDeviceId()
    }

    func fetchDeviceId() {
        guard let cgmManager else {
            logger.error("No CGM manager to start scanning")
            return
        }

        if let deviceId = cgmManager.state.deviceId, !deviceId.isEmpty {
            logger.debug("Bypass deviceID fetch")
            startScanning()
            return
        }

        guard let accessToken = cgmManager.state.accessToken else {
            logger.error("No access token available...")
            return
        }

        Task {
            guard let id = await AuthHttp.getDeviceId(token: accessToken) else {
                logger.error("Failed to get device id")
                return
            }

            cgmManager.state.deviceId = id
            startScanning()
        }
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
