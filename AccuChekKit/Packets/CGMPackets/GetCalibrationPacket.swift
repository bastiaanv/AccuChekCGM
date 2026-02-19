import CoreBluetooth
import Foundation

class GetCalibrationPacket: AccuChekBasePacket {
    var describe: String {
        "[GetCalibrationPacket] nextCalibrationOffset=\(nextCalibrationOffset), calibrationStatus=\(calibrationStatus)"
    }

    var receivedResponse: Bool = false
    var nextCalibrationOffset: UInt16 = 0
    var calibrationStatus: UInt8 = 0

    let characteristics: [CBUUID] = [
        CBUUID.CGM_CONTROL_POINT
    ]

    let recordIndex: UInt16
    init(recordIndex: UInt16) {
        self.recordIndex = recordIndex
    }

    func getRequest() -> Data {
        var data = Data([5])
        data.append(recordIndex.toData())

        return data.appendingCrc()
    }

    func parseResponse(data: Data) {
        guard data[0] == 0x06 else {
            // Received wrong message
            return
        }

        receivedResponse = true
        nextCalibrationOffset = data.getUInt16(offset: 6)
        calibrationStatus = data[10]
    }

    func isComplete() -> Bool {
        receivedResponse
    }
}
