import Foundation

class CgmStartTime {
    let start: Date

    init(_ data: Data) {
        let timezone = SessionTimeZone(rawValue: data[7])?.timeZone
        let components = DateComponents(
            timeZone: timezone,
            year: Int(data.getUInt16(offset: 0)),
            month: Int(data[2]),
            day: Int(data[3]),
            hour: Int(data[4]),
            minute: Int(data[5]),
            second: Int(data[6])
        )
        start = Calendar.current.date(from: components) ?? Date.distantPast
    }

    var describe: String {
        "[CgmStartTime] start: \(start)"
    }
}
