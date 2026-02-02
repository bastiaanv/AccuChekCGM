import Foundation

class SetAcClientNonceFixedPacket: AcsBasePacket {
    var numberOfResponses: Int {
        1
    }

    var success: UInt8 = 0

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
        success = data[1]
    }

    func isComplete() -> Bool {
        success == 0x01
    }
}
