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

    private static let identifierPrefix = "com.bastiaanv.AccuChekKit."
    var notification: NotificationContent? {
        switch self {
        case .sessionStopped:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "sessionStopped",
                title: String(localized: "Sensor expired!", comment: "Title sensor expired"),
                content: String(localized: "Replace your sensor now", comment: "description sensor expired"),
            )
        case .deviceBatteryLow:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "deviceBatteryLow",
                title: String(localized: "Sensor battery is low", comment: "title battery low"),
                content: String(localized: "Replace your sensor now", comment: "description sensor expired"),
            )
        case .generalDeviceFaultOccuredInSensor:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "sensorMalfunction",
                title: String(localized: "Sensor is malfunctioning", comment: "title sensor fault"),
                content: String(localized: "Replace your sensor now", comment: "description sensor expired"),
            )
        case .calibrationRecommended:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "calibrationRecommended",
                title: String(localized: "Sensor calibration", comment: "title sensor fault"),
                content: String(localized: "Calibration is recommended", comment: "description sensor calibration recommend"),
            )
        case .calibrationRequired:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "calibrationRequired",
                title: String(localized: "Sensor calibration", comment: "title sensor fault"),
                content: String(localized: "Calibrate your sensor now", comment: "description sensor calibration required"),
            )
        case .sensorTemperatureTooHigh:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "sensorTemperatureTooHigh",
                title: String(localized: "Sensor temperature too high", comment: "title sensor temp high"),
                content: String(
                    localized: "Go to a cooler place to cooldown the sensor",
                    comment: "description sensor temp high"
                ),
            )
        case .sensorTemperatureTooLow:
            return NotificationContent(
                type: self,
                identifier: SensorStatusEnum.identifierPrefix + "sensorTemperatureTooLow",
                title: String(localized: "Sensor temperature too low", comment: "title sensor temp low"),
                content: String(localized: "Go to a warmer place to warmup the sensor", comment: "description sensor temp low"),
            )
        default: return nil
        }
    }

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
