import CoreBluetooth
import Foundation

class GetLastCgmMeasurementPacket: AccuChekBasePacket {
    private var receivedFinalMessage = false
    var measurements: [CgmMeasurement] = []

    var describe: String {
        "[GetLastCgmMeasurementPacket] count=\(measurements.count)"
    }

    var characteristics: [CBUUID] {
        [CBUUID.CGM_MEASUREMENT, CBUUID.CGM_RACP]
    }

    let startOffset: UInt16
    init(startOffset: UInt16) {
        self.startOffset = startOffset
    }

    func getRequest() -> Data {
        var data = Data([1, 3, 1])
        data.append(startOffset.toData())

        return data
    }

    func parseResponse(data: Data) {
        if data[0] == 0x06 {
            receivedFinalMessage = true
            return
        }

        let measurement = CgmMeasurement(data)
        if measurement.glucoseInMgDl >= 0x01F4 {
            // Ignore glucose above 500 mgdl
            return
        }
        measurements.append(measurement)
    }

    func isComplete() -> Bool {
        receivedFinalMessage
    }
}
