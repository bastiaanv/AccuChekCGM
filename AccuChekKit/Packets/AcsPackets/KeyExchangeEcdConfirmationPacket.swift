import CryptoKit
import Foundation

class KeyExchangeEcdConfirmationPacket: AccuChekBasePacket {
    let numberOfResponses: Int = 1

    var describe: String {
        "[KeyExchangeEcdConfirmationPacket] confirmationCode=\(confirmationCode.hexString())"
    }

    var confirmationCode = Data()

    let descriptor: EcdhKeyDescriptor
    let confirmation: Data
    init(descriptor: EcdhKeyDescriptor, code: Data) {
        self.descriptor = descriptor
        confirmation = code
    }

    func getRequest() -> Data {
        var data = Data([AcsOpcode.keyExchangeEcdhConfirmationCode.rawValue])
        data.append(descriptor.keyId.toData())
        data.append(confirmation)

        return data
    }

    func parseResponse(data: Data) {
        confirmationCode = data[3 ..< 32]
    }

    func isComplete() -> Bool {
        confirmationCode.count == 32
    }

    public static func calculateConfirmation(
        randomNumber: Data,
        pin: String,
        aesKey: SymmetricKey,
        keyExchange: KeyExchangeEcdhPacket,
        privateKey: P256.KeyAgreement.PrivateKey
    ) -> Data {
        let remotePublic = keyExchange.xCoord + keyExchange.yCoord
        let localPublic = privateKey.publicKey.derRepresentation
        let localPublicKeyRaw = localPublic.subdata(in: 25 ..< localPublic.count)
        let rawKey = aesKey.withUnsafeBytes { Data($0) }

        var auth = Data(repeating: 0, count: 32 - pin.count)
        auth.append(pin.asciiValues)

        let salt = mac(remotePublic, localPublicKeyRaw)
        let confirmationKey = mac(salt, rawKey, auth)

        return mac(confirmationKey, randomNumber)
    }

    private static func mac(_ first: Data, _ second: Data, _ third: Data? = nil) -> Data {
        var hmac = HMAC<SHA256>(key: SymmetricKey(data: Data(repeating: 0, count: 32)))
        hmac.update(data: first)
        hmac.update(data: second)

        if let third = third {
            hmac.update(data: third)
        }

        return hmac.finalize().withUnsafeBytes { Data($0) }
    }
}
