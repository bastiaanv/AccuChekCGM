import Foundation

class GetAttMtuPacket: AcsBasePacket {
    public var mtu: UInt16 = 0

    var numberOfResponses: Int {
        1
    }

    func getRequest() -> Data {
        createOpCodePacket(code: AcsOpcode.getAttMtu)
    }

    func parseResponse(data: Data) {
        if data[0] != AcsOpcode.attMtuResponse.rawValue {
            return
        }

        mtu = data.getUInt16(offset: 1)
        return
    }

    func isComplete() -> Bool {
        mtu > 0
    }
}
