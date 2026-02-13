import CoreBluetooth
import Foundation

class SetAcClientNonceFixedPacket: AccuChekBasePacket {
    var describe: String {
        "[SetAcClientNonceFixedPacket] responseCode=\(responseCode)"
    }

    var characteristics: [CBUUID] {
        [CBUUID.ACS_CONTROL_POINT]
    }

    var responseCode: UInt8 = 0

    let aesGcmDescriptor: AesCgmKeyDescriptor
    let fixedNonce: Data
    init(aesGcmDescriptor: AesCgmKeyDescriptor, fixedNonce: Data) {
        self.aesGcmDescriptor = aesGcmDescriptor
        self.fixedNonce = fixedNonce
    }

    func getRequest() -> Data {
        var data = Data([AcsOpcode.setAcClientNonceFixed.rawValue])
        data.append(aesGcmDescriptor.keyId.toData())
        data.append(Data(fixedNonce.reversed()))

        return data
    }

    func parseResponse(data: Data) {
        responseCode = data[1]
    }

    func isComplete() -> Bool {
        responseCode == 0x01
    }
}
