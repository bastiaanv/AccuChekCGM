import Combine
import CryptoKit
import LoopKit
import SwiftUI

class PairingViewModel: ObservableObject {
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

        cgmManager.bluetooth.startScan { result in
            if result.deviceName != "AC-1R000667359" {
                self.logger.warning("This is not the device you are looking for : \(result.deviceName)")
                return
            }

            cgmManager.state.serialNumber = result.deviceName
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
}
