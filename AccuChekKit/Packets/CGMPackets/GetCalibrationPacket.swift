import CoreBluetooth
import Foundation

class GetCalibrationPacket: AccuChekBasePacket {
    var describe: String {
        "[GetCalibrationPacket] nextCalibrationOffset=\(nextCalibrationOffset), calibrationStatus=\(calibrationStatus)"
    }

    var receivedResponse: Bool = false
    var nextCalibrationOffset: UInt16 = 0
    var calibrationStatus: CalibrationStatus = .unknown
    var recordNumber: UInt16 = 0

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
        recordNumber = data.getUInt16(offset: 8)
        calibrationStatus = CalibrationStatus(rawValue: data[10]) ?? .unknown
    }

    func isComplete() -> Bool {
        receivedResponse
    }
}

enum CalibrationStatus: UInt8 {
    case ok = 0x00
    case rejected = 0x01
    case outOfRange = 0x02
    case rejectedAndOutOfRange = 0x03
    case processing = 0x04

    case unknown = 0xFF
}
