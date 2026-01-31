import Foundation

class GetCertificateNonce: AcsBasePacket {
    public var nonce: UInt16 = 0
    var numberOfResponses: Int {
        1
    }

    func getRequest() -> [Data] {
        createOpCodePacket(code: AcsOpcode.getCertificateNonce)
    }

    func parseResponse(data: Data) {
        if data[0] != AcsOpcode.getCertificateNonceResponse.rawValue {
            return
        }

        nonce = data.getUInt16(offset: 1)
        return
    }

    func isComplete() -> Bool {
        nonce > 0
    }
}
