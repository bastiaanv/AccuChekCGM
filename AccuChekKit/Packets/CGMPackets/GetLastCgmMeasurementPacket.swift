import Foundation

class GetLastCgmMeasurementPacket: AccuChekBasePacket {
    private var receivedFinalMessage = false
    var measurements: [CgmMeasurement] = []

    var describe: String {
        "[GetLastCgmMeasurementPacket] count=\(measurements.count)"
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

        measurements.append(CgmMeasurement(data))
    }

    func isComplete() -> Bool {
        receivedFinalMessage
    }
}
