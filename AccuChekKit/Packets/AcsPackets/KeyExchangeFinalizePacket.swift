import CoreBluetooth
import Foundation

class KeyExchangeFinalizePacket: AccuChekBasePacket {
    var describe: String {
        "[KeyExchangeFinalizePacket] confirmationCode=\(confirmationCode.hexString())"
    }

    var characteristics: [CBUUID] {
        [CBUUID.ACS_CONTROL_POINT]
    }

    var confirmationCode = Data()

    let descriptor: EcdhKeyDescriptor
    let randomNumber: Data
    init(descriptor: EcdhKeyDescriptor, randomNumber: Data) {
        self.descriptor = descriptor
        self.randomNumber = randomNumber
    }

    func getRequest() -> Data {
        var data = Data([AcsOpcode.keyExchangeEcdhConfirmationRandomNumber.rawValue])
        data.append(descriptor.keyId.toData())
        data.append(randomNumber)

        return data
    }

    func parseResponse(data: Data) {
        confirmationCode = data[3 ..< data.count]
    }

    func isComplete() -> Bool {
        confirmationCode.count == 32
    }
}
