import Foundation

class StartKeyExchangePacket: AccuChekBasePacket {
    let numberOfResponses: Int = 1

    var describe: String {
        "[StartKeyExchangePacket] responseCode=\(responseCode)"
    }

    var responseCode: UInt8 = 0

    let decriptor: EcdhKeyDescriptor
    init(decriptor: EcdhKeyDescriptor) {
        self.decriptor = decriptor
    }

    func getRequest() -> Data {
        var data = Data([AcsOpcode.startKeyExchange.rawValue])
        data.append(decriptor.keyId.toData())
        data.append(Data([3, 255]))

        return data
    }

    func parseResponse(data: Data) {
        responseCode = data[2]
    }

    func isComplete() -> Bool {
        responseCode == 0x01
    }
}
