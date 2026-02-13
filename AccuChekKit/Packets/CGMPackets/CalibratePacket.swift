import CoreBluetooth
import Foundation

class CalibratePacket: AccuChekBasePacket {
    var describe: String {
        "[CalibratePacket] responseCode=\(responseCode)"
    }

    var characteristics: [CBUUID] {
        [CBUUID.CGM_CONTROL_POINT]
    }

    var responseCode: UInt8 = 0

    let glucoseInMgDl: UInt16
    let cgmStartTime: Date
    init(glucoseInMgDl: UInt16, cgmStartTime: Date) {
        self.glucoseInMgDl = glucoseInMgDl
        self.cgmStartTime = cgmStartTime
    }

    func getRequest() -> Data {
        let currentOffset = Date.now.timeIntervalSince(cgmStartTime).minutes

        var data = Data([4])
        data.append(glucoseInMgDl.toData())
        data.append(Data([17]))
        data.append(UInt16(currentOffset).toData())
        data.append(UInt16(0).toData())
        data.append(Data([0]))

        return data
    }

    func parseResponse(data: Data) {
        responseCode = data[2]
    }

    func isComplete() -> Bool {
        responseCode != 0
    }

    enum NextCalibration {}
}
