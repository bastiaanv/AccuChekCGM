import Foundation

class KeyExchangeEcdhPacket: AccuChekBasePacket {
    var describe: String {
        "[KeyExchangeEcdhPacket] xCoord=\(xCoord.hexString()), yCoord=\(yCoord.hexString())"
    }

    var xCoord = Data()
    var yCoord = Data()

    let decriptor: EcdhKeyDescriptor
    let certificate: Data
    init(decriptor: EcdhKeyDescriptor, certificate: Data) {
        self.decriptor = decriptor
        self.certificate = certificate
    }

    func getRequest() -> Data {
        var data = Data([AcsOpcode.keyExchangeEcdh.rawValue])
        data.append(decriptor.keyId.toData())
        data.append(UInt16(certificate.count).toData())
        data.append(certificate)

        return data
    }

    func parseResponse(data: Data) {
        let lengthX = Int(data[3])
        xCoord = Data(data.subdata(in: 4 ..< (4 + lengthX)))

        let lengthY = data[4 + lengthX]
        let startY = 5 + lengthX
        yCoord = Data(data.subdata(in: startY ..< (startY + Int(lengthY))))
    }

    func isComplete() -> Bool {
        !xCoord.isEmpty && !yCoord.isEmpty
    }
}
