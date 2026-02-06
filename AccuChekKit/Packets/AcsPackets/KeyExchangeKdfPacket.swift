import Foundation

class KeyExchangeKdfPacket: AccuChekBasePacket {
    let numberOfResponses: Int = 1

    var describe: String {
        "[KeyExchangeKdfPacket] salt=\(salt.hexString()), info=\(info.hexString())"
    }

    var salt = Data()
    var info = Data()

    let descriptor: EcdhKeyDescriptor
    init(descriptor: EcdhKeyDescriptor) {
        self.descriptor = descriptor
    }

    func getRequest() -> Data {
        var data = Data([AcsOpcode.keyExchangeKdf.rawValue])
        data.append(descriptor.keyId.toData())

        return data
    }

    func parseResponse(data: Data) {
        let saltSize = Int(data[3])
        salt = Data(data[4 ..< 4 + saltSize])

        let infoSize = Int(data[4 + saltSize])
        let infoStart = 5 + saltSize
        info = Data(data[infoStart ..< infoStart + infoSize])
    }

    func isComplete() -> Bool {
        !salt.isEmpty && !info.isEmpty
    }
}
