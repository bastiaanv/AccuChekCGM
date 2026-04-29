import Combine
import CryptoKit
import LoopKit
import SwiftUI

enum PairingState {
    case scanning
    case connecting

    var text: String {
        switch self {
        case .scanning:
            return String(localized: "Scanning for Accu Chek CGMs", comment: "scanning")
        case .connecting:
            return String(localized: "Connecting with your Accu Chek CGM!", comment: "connecting")
        }
    }

    var desciption: String {
        switch self {
        case .scanning:
            return String(localized: "Keep the app in the foreground while scanning...", comment: "scanning")
        case .connecting:
            return String(localized: "Please be patience, this can take a full minute", comment: "connecting")
        }
    }
}

class PairingViewModel: ObservableObject {
    @Published var state: PairingState = .scanning
    @Published var foundDevices: [ScanResult] = []
    @Published var foundDeviceLast: ScanResult? = nil
    @Published var unsupportedDevice: ScanResult? = nil
    @Published var showConfirmationAlert = false
    @Published var showUnsupportedDeviceAlert = false

    private let logger = AccuChekLogger(category: "PairingViewModel")

    private let cgmManager: AccuChekCgmManager?
    private let nextStep: () -> Void
    init(_ cgmManager: AccuChekCgmManager?, nextStep: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.nextStep = nextStep

        startScanning()
    }

    func startScanning() {
        guard let cgmManager else {
            logger.error("No CGM manager to start scanning")
            return
        }

        let nextDeviceName = cgmManager.state.nextDeviceName
        let previousDeviceName = cgmManager.state.previousDeviceName
        cgmManager.bluetooth.startScan { result in
            if result.deviceName == previousDeviceName {
                self.logger.warning("Found previous CGM while scanning: \(result.deviceName)")
                return
            }

            if result.hasAcsSupport {
                // Found unsupported device...
                cgmManager.bluetooth.stopScan()
                DispatchQueue.main.async {
                    self.foundDevices.append(result)
                    self.unsupportedDevice = result
                    self.showUnsupportedDeviceAlert = true
                }
                return
            }

            if let nextDeviceName, result.deviceName == nextDeviceName {
                self.logger.info("Auto connect to device!")
                cgmManager.bluetooth.stopScan()
                self.connect(result: result)
                return
            }

            // Found device (propably)
            cgmManager.bluetooth.stopScan()
            DispatchQueue.main.async {
                self.foundDevices.append(result)
                self.foundDeviceLast = result
                self.showConfirmationAlert = true
            }
        }
    }

    func connect(result: ScanResult) {
        guard let cgmManager else {
            logger.error("No CGM manager to start scanning")
            return
        }

        state = .connecting

        cgmManager.state.deviceName = result.deviceName
        cgmManager.notifyStateDidChange()

        cgmManager.bluetooth.connect(to: result.peripheral) { error in
            if let error {
                self.logger.error("Failed to connect to CGM: \(error)")
                return
            }

            cgmManager.state.onboarded = true
            cgmManager.state.deviceName = result.deviceName
            cgmManager.notifyStateDidChange()

            self.nextStep()
        }
    }
}
