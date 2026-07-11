import Foundation
import LoopKit

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

    private static let managerIdentifier = "AccuChekSmartGuide"
    private static let identifierPrefix = "com.bastiaanv.AccuChekKit."
    var notification: LoopKit.Alert? {
        guard let identifier = alertIdentifier, let content = alertContent else {
            return nil
        }
        
        return Alert(
            identifier: identifier,
            foregroundContent: content,
            backgroundContent: content,
            trigger: .immediate
        )
    }
    
    private var alertContent: Alert.Content? {
        switch self {
        case .sessionStopped:
            return Alert.Content(
                title: String(localized: "Sensor expired!", comment: "Title sensor expired"),
                body: String(localized: "Replace your sensor now", comment: "description sensor expired"),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        case .deviceBatteryLow:
            return Alert.Content(
                title: String(localized: "Sensor battery is low", comment: "title battery low"),
                body: String(localized: "Replace your sensor now", comment: "description sensor expired"),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        case .generalDeviceFaultOccuredInSensor:
            return Alert.Content(
                title: String(localized: "Sensor is malfunctioning", comment: "title sensor fault"),
                body: String(localized: "Replace your sensor now", comment: "description sensor expired"),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        case .calibrationRecommended:
            return Alert.Content(
                title: String(localized: "Sensor calibration", comment: "title sensor fault"),
                body: String(localized: "Calibration is recommended", comment: "description sensor calibration recommend"),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        case .calibrationRequired:
            return Alert.Content(
                title: String(localized: "Sensor calibration", comment: "title sensor fault"),
                body: String(localized: "Calibrate your sensor now", comment: "description sensor calibration required"),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        case .sensorTemperatureTooHigh:
            return Alert.Content(
                title: String(localized: "Sensor temperature too high", comment: "title sensor temp high"),
                body: String(
                    localized: "Go to a cooler place to cooldown the sensor",
                    comment: "description sensor temp high"
                ),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        case .sensorTemperatureTooLow:
            return Alert.Content(
                title: String(localized: "Sensor temperature too low", comment: "title sensor temp low"),
                body: String(localized: "Go to a warmer place to warmup the sensor", comment: "description sensor temp low"),
                acknowledgeActionButtonLabel: String(localized: "OK", comment: "Acknoledge alert")
            )
        default: return nil
        }
    }
    
    private var alertIdentifier: Alert.Identifier? {
        switch self {
        case .sessionStopped:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "sessionStopped"
            )
        case .deviceBatteryLow:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "deviceBatteryLow"
            )
        case .generalDeviceFaultOccuredInSensor:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "sensorMalfunction"
            )
        case .calibrationRecommended:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "calibrationRecommended"
            )
        case .calibrationRequired:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "calibrationRequired"
            )
        case .sensorTemperatureTooHigh:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "temperatureTooHigh"
            )
        case .sensorTemperatureTooLow:
            return Alert.Identifier(
                managerIdentifier: Self.managerIdentifier,
                alertIdentifier: Self.identifierPrefix + "temperatureTooLow"
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
