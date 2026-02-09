import Foundation

class GetAttMtuPacket: AccuChekBasePacket {
    public var mtu: UInt16 = 0

    var describe: String {
        "[GetAttMtuPacket] mtu=\(mtu)"
    }

    func getRequest() -> Data {
        createAcsOpCodePacket(code: AcsOpcode.getAttMtu)
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
