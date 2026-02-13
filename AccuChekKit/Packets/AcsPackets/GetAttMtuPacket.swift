import CoreBluetooth
import Foundation

class GetAttMtuPacket: AccuChekBasePacket {
    public var mtu: UInt16 = 0

    var describe: String {
        "[GetAttMtuPacket] mtu=\(mtu)"
    }

    var characteristics: [CBUUID] {
        [CBUUID.ACS_CONTROL_POINT]
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
