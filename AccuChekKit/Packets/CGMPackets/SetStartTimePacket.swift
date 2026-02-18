import CoreBluetooth
import Foundation

class SetStartTimePacket: AccuChekBasePacket {
    var describe: String {
        "[SetStartTimePacket] receivedResponse=\(receivedResponse)"
    }

    var characteristics: [CBUUID] {
        [CBUUID.CGM_SESSION_START]
    }

    var receivedResponse: Bool = false

    private let logger = AccuChekLogger(category: "SetStartTimePacket")
    let date: Date
    init(date: Date) {
        self.date = date
    }

    func getRequest() -> Data {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let hour = components.hour,
            let minute = components.minute,
            let second = components.second
        else {
            logger.error("Failed to parse date components...")
            return Data()
        }

        let data = Data([
            UInt8(year % 256),
            UInt8(year / 256),
            UInt8(month),
            UInt8(day),
            UInt8(hour),
            UInt8(minute),
            UInt8(second),
            0, // Always use UTC as time
            DstOffset.standardTime.rawValue
        ])

        return data.appendingCrc()
    }

    func parseResponse(data _: Data) {
        receivedResponse = true
    }

    func isComplete() -> Bool {
        receivedResponse
    }
}
