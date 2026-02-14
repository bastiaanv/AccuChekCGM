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
            return LocalizedString("Scanning for Accu Chek CGMs", comment: "scanning")
        case .connecting:
            return LocalizedString("Connecting with your Accu Chek CGM!", comment: "connecting")
        }
    }
    
    var desciption: String {
        switch self {
        case .scanning:
            return LocalizedString("Keep the app in the foreground while scanning...", comment: "scanning")
        case .connecting:
            return LocalizedString("Please be patience, this can take a full minute", comment: "connecting")
        }
    }
}

class PairingViewModel: ObservableObject {
    @Published var state: PairingState = .scanning
    @Published var foundDevices: [ScanResult] = []
    @Published var foundDeviceLast: ScanResult? = nil
    @Published var showConfirmationAlert = false

    private let logger = AccuChekLogger(category: "PairingViewModel")

    private let cgmManager: AccuChekCgmManager?
    private let nextStep: () -> Void
    init(_ cgmManager: AccuChekCgmManager?, nextStep: @escaping () -> Void) {
        self.cgmManager = cgmManager
        self.nextStep = nextStep

        startScanning()
    }

//    func fetchCertificate() {
//        guard let cgmManager else {
//            logger.error("No CGM manager to check certificate")
//            return
//        }
//
//        if cgmManager.state.certificate != nil {
//            startScanning()
//            return
//        }
//
//        guard let accessToken = cgmManager.state.accessToken, let keyAgreement = cgmManager.state.keyAgreementPrivate else {
//            logger.error("No access token or keyAgreement available...")
//            return
//        }
//
//        Task {
//            do {
//                let privateKey = try P256.KeyAgreement.PrivateKey(derRepresentation: keyAgreement)
//                let request = CertificateHttp.CertificateRequest(
//                    privateKey: privateKey,
//                    sensorRevisionInfo: SensorInfo.default(),
//                    authToken: accessToken
//                )
//                guard let certificate = await CertificateHttp.getCertificate(request: request) else {
//                    self.logger.error("Failed to get certificate")
//                    return
//                }
//
//                cgmManager.state.certificate = certificate
//                startScanning()
//            } catch {
//                self.logger.error("Error during private key construct: \(error.localizedDescription)")
//            }
//        }
//    }

    func startScanning() {
        guard let cgmManager else {
            logger.error("No CGM manager to start scanning")
            return
        }

        let previousDeviceName = cgmManager.state.deviceName
        cgmManager.bluetooth.startScan { result in
            if result.deviceName != previousDeviceName {
                self.logger.warning("Found previous CGM while scanning: \(result.deviceName)")
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
