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
                identifier: SensorStatusEnum.identifierPrefix + "sessionStopped",
                title: LocalizedString("Sensor expired!", comment: "Title sensor expired"),
                content: LocalizedString("Replace your sensor now", comment: "description sensor expired"),
            )
        case .deviceBatteryLow:
            return NotificationContent(
                identifier: SensorStatusEnum.identifierPrefix + "deviceBatteryLow",
                title: LocalizedString("Sensor battery is low", comment: "title battery low"),
                content: LocalizedString("Replace your sensor now", comment: "description sensor expired"),
            )
        case .generalDeviceFaultOccuredInSensor,
             .sensorMalfunction:
            return NotificationContent(
                identifier: SensorStatusEnum.identifierPrefix + "sensorMalfunction",
                title: LocalizedString("Sensor is malfunctioning", comment: "title sensor fault"),
                content: LocalizedString("Replace your sensor now", comment: "description sensor expired"),
            )
        case .calibrationRecommended:
            return NotificationContent(
                identifier: SensorStatusEnum.identifierPrefix + "calibrationRecommended",
                title: LocalizedString("Sensor calibration", comment: "title sensor fault"),
                content: LocalizedString("Calibration is recommended", comment: "description sensor calibration recommend"),
            )
        case .calibrationRequired:
            return NotificationContent(
                identifier: SensorStatusEnum.identifierPrefix + "calibrationRequired",
                title: LocalizedString("Sensor calibration", comment: "title sensor fault"),
                content: LocalizedString("Calibrate your sensor now", comment: "description sensor calibration required"),
            )
        case .sensorTemperatureTooHigh:
            return NotificationContent(
                identifier: SensorStatusEnum.identifierPrefix + "sensorTemperatureTooHigh",
                title: LocalizedString("Sensor temperature too high", comment: "title sensor temp high"),
                content: LocalizedString("Go to a cooler place to cooldown the sensor", comment: "description sensor temp high"),
            )
        case .sensorTemperatureTooLow:
            return NotificationContent(
                identifier: SensorStatusEnum.identifierPrefix + "sensorTemperatureTooLow",
                title: LocalizedString("Sensor temperature too low", comment: "title sensor temp low"),
                content: LocalizedString("Go to a warmer place to warmup the sensor", comment: "description sensor temp low"),
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
