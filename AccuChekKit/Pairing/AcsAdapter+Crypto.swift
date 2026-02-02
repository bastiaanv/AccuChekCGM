import CoreBluetooth
internal import X509
internal import Crypto
import Foundation

extension AcsAdapter {
    func generateKeyPair() -> (P256.Signing.PrivateKey, P256.Signing.PublicKey, Data) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let nonce = Data.randomSecure(length: 4)

        return (privateKey, publicKey, nonce)
    }

    func doKeyExchange(certificateNonce: UInt16) {
        guard
            let aesGcmDescriptor = descriptorPacket.getAesCgm(),
            let ecdhDescriptor = descriptorPacket.getEcdh()
        else {
            logger.error("KeyDescriptor is missing")
            return
        }

        let semaphore = DispatchSemaphore(value: 0)
        let (privateKey, publicKey, fixedNoncePrefix) = generateKeyPair()

        var certificate: Certificate?
        Task {
            let sensorRevision = self.sensorRevisionInfo ?? SensorRevisionInfo.default()
            let request = CertificateHttp.CertificateRequest(
                serialNumber: sensorRevision.serialNumber,
                certificateNonce: certificateNonce,
                dcdSerialNumber: cgmManager.state.deviceId,
                privateKey: privateKey,
                sensorRevisionInfo: sensorRevision,
                authToken: cgmManager.state.accessToken ?? ""
            )
            certificate = await CertificateHttp.getCertificate(request: request)
            semaphore.signal()
        }

        semaphore.wait()
        guard let certificate else {
            logger.error("Failed to get certificate")
            return
        }

        let noncePacket = SetAcClientNonceFixedPacket(aesGcmDescriptor: aesGcmDescriptor, fixedNonce: fixedNoncePrefix)
        if !peripheralManager.write(packet: noncePacket, service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT) {
            logger.error("Failed to write SetAcClientNonceFixedPacket - success: \(noncePacket.success)")
            return
        }
    }
}
