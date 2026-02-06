import Foundation

class SensorStatus {
    let offset: UInt16
    let status: [SensorStatusEnum]
    init(data: Data) {
        offset = data.getUInt16(offset: 0)
        status = SensorStatus.parseStatusAnnunciation(Data(data.subdata(in: 2 ..< 5)))
    }

    var describe: String {
        "[SensorStatus] offset=\(offset), status=\(status.map { String($0.rawValue) }.joined(separator: ", "))"
    }

    static func parseStatusAnnunciation(_ status: Data) -> [SensorStatusEnum] {
        var result: [SensorStatusEnum] = []

        for value in SensorStatusEnum.allCases {
            let rawValue = Int(value.rawValue)
            let byteIndex = rawValue / 8
            let bitIndex = rawValue % 8

            if byteIndex < status.count {
                let isSet = ((status[byteIndex] >> bitIndex) & 1) == 1
                if isSet {
                    result.append(value)
                }
            }
        }

        return result
    }
}

enum SensorStatusEnum: UInt8 {
    case sessionStopped = 0
    case deviceBatteryLow = 1
    case sensorTypeIncorrectForDevice = 2
    case sensorMalfunction = 3
    case deviceSpecificAlert = 4
    case generalDeviceFaultOccuredInSensor = 5
    case timeSynchronizationRequired = 8
    case calibrationNotAllowed = 9
    case calibrationRecommended = 10
    case calibrationRequired = 11
    case sensorTemperatureTooHigh = 12
    case sensorTemperatureTooLow = 13
    case sensorResultLowerThanPatientLowLevel = 16
    case sensorResultHigherThanPatientHighLevel = 17
    case sensorResultLowerThanHypoLevel = 18
    case sensorResultHigherThanHyperLevel = 19
    case sensorRateOfDecreaseExceeded = 20
    case sensorRateOfIncreaseExceeded = 21
    case sensorResultLowerThanDeviceCanProcess = 22
    case sensorResultHigherThanDeviceCanProcess = 23

    static let allCases: [SensorStatusEnum] = [
        .sessionStopped,
        .deviceBatteryLow,
        .sensorTypeIncorrectForDevice,
        .sensorMalfunction,
        .deviceSpecificAlert,
        .generalDeviceFaultOccuredInSensor,
        .timeSynchronizationRequired,
        .calibrationNotAllowed,
        .calibrationRecommended,
        .calibrationRequired,
        .sensorTemperatureTooHigh,
        .sensorTemperatureTooLow,
        .sensorResultLowerThanPatientLowLevel,
        .sensorResultHigherThanPatientHighLevel,
        .sensorResultLowerThanHypoLevel,
        .sensorResultHigherThanHyperLevel,
        .sensorRateOfDecreaseExceeded,
        .sensorRateOfIncreaseExceeded,
        .sensorResultLowerThanDeviceCanProcess,
        .sensorResultHigherThanDeviceCanProcess
    ]
}
