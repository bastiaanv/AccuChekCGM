import CoreBluetooth
import CryptoKit
import Foundation

extension AcsAdapter {
    func generateKeyPair() -> (P256.KeyAgreement.PrivateKey, Data) {
        let privateKey = P256.KeyAgreement.PrivateKey()
        let nonce = Data.randomSecure(length: 4)

        return (privateKey, nonce)
    }

    func doKeyExchange() -> Bool {
        guard
            let aesGcmDescriptor = descriptorPacket.getAesCgm(),
            let ecdhDescriptor = descriptorPacket.getEcdh()
        else {
            logger.error("KeyDescriptor is missing")
            return false
        }

        let (privateKey, fixedNoncePrefix) = generateKeyPair()

        guard let certificate = cgmManager.state.certificate else {
            logger.error("No certificate available...")
            return false
        }

        let noncePacket = SetAcClientNonceFixedPacket(aesGcmDescriptor: aesGcmDescriptor, fixedNonce: fixedNoncePrefix)
        if !peripheralManager.write(packet: noncePacket, service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT) {
            logger.error("Failed to write SetAcClientNonceFixedPacket - responseCode: \(noncePacket.responseCode)")
            return false
        }

        let startKeyExchangePacket = StartKeyExchangePacket(decriptor: ecdhDescriptor)
        if !peripheralManager.write(
            packet: startKeyExchangePacket,
            service: CBUUID.ACS_SERVICE,
            characteristic: CBUUID.ACS_CONTROL_POINT
        ) {
            logger.error("Failed to write StartKeyExchangePacket - responseCode: \(startKeyExchangePacket.responseCode)")
            return false
        }

        let keyExchangeEcdhPacket = KeyExchangeEcdhPacket(decriptor: ecdhDescriptor, certificate: certificate.der)
        if !peripheralManager.write(
            packet: keyExchangeEcdhPacket,
            service: CBUUID.ACS_SERVICE,
            characteristic: CBUUID.ACS_CONTROL_POINT
        ) {
            logger.error("Failed to write KeyExchangeEcdhPacket")
            return false
        }

        let keyExchangeKdfPacket = KeyExchangeKdfPacket(descriptor: ecdhDescriptor)
        if !peripheralManager.write(
            packet: keyExchangeKdfPacket,
            service: CBUUID.ACS_SERVICE,
            characteristic: CBUUID.ACS_CONTROL_POINT
        ) {
            logger.error("Failed to write keyExchangeKdfPacket")
            return false
        }

        guard let aesKey = deriveKey(
            privateKey: privateKey,
            ecdhParameters: keyExchangeEcdhPacket,
            kdfParameters: keyExchangeKdfPacket
        ) else {
            logger.error("Failed to derive key")
            return false
        }

        guard let pin = cgmManager.state.pinCode else {
            logger.error("No pin available...")
            return false
        }

        let randomCode = Data.randomSecure(length: 32)
        let confirmationCode = KeyExchangeEcdConfirmationPacket.calculateConfirmation(
            randomNumber: randomCode,
            pin: pin,
            aesKey: aesKey,
            keyExchange: keyExchangeEcdhPacket,
            privateKey: privateKey
        )
        let confirmationCodePacket = KeyExchangeEcdConfirmationPacket(descriptor: ecdhDescriptor, code: confirmationCode)
        if !peripheralManager.write(
            packet: confirmationCodePacket,
            service: CBUUID.ACS_SERVICE,
            characteristic: CBUUID.ACS_CONTROL_POINT
        ) {
            logger.error("Failed to write KeyExchangeEcdConfirmationPacket")
            return false
        }

        let finalizePacket = KeyExchangeFinalizePacket(descriptor: ecdhDescriptor, randomNumber: randomCode)
        if !peripheralManager.write(
            packet: finalizePacket,
            service: CBUUID.ACS_SERVICE,
            characteristic: CBUUID.ACS_CONTROL_POINT
        ) {
            logger.error("Failed to write CalculateConfirmationCodePacket")
            return false
        }

        if confirmationCode != finalizePacket.confirmationCode {
            logger.error("Failed to calculate confirmation code")
            return false
        }

        logger.info("Key exchange success!")
        peripheralManager.aesCgmKey = aesKey
        cgmManager.state.aesKey = aesKey.withUnsafeBytes { Data($0) }

        return true
    }

    private func deriveKey(
        privateKey: P256.KeyAgreement.PrivateKey,
        ecdhParameters: KeyExchangeEcdhPacket,
        kdfParameters: KeyExchangeKdfPacket
    ) -> SymmetricKey? {
        do {
            var rawKey = Data([0x04])
            rawKey.append(ecdhParameters.xCoord)
            rawKey.append(ecdhParameters.yCoord)
            let keyAgreement = try P256.KeyAgreement.PublicKey(x963Representation: rawKey)

            let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: keyAgreement)

            return sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: kdfParameters.salt,
                sharedInfo: kdfParameters.info,
                outputByteCount: 16
            )
        } catch {
            logger.error("Failed to create P256.KeyAgreement.PublicKey - error: \(error.localizedDescription)")
            return nil
        }
    }
}
