import Foundation
import LoopKit
import LoopAlgorithm

class CgmMeasurement {
    let flags: UInt8
    let glucoseInMgDl: UInt16
    let timeOffset: TimeInterval
    let statusValues: Data
    let trend: Double?
    let quality: Double?
    let isValid: Bool
    let condition: GlucoseCondition?

    // The sensor's measurable range is between
    // 40-400mg/dL (2.22-22.2mmol/L) as per the device spec
    private enum MeasurableRangeMgDl {
        static let low: UInt16 = 40
        static let high: UInt16 = 400
    }

    init(_ data: Data) {
        flags = data[1]
        timeOffset = TimeInterval.minutes(Double(data.getUInt16(offset: 4)))

        var statusValues = Data()

        let hasStatus = (flags & CgmFlag.status.rawValue) != 0
        let statusByte: UInt8 = hasStatus ? data[6] : 0
        if hasStatus {
            statusValues.append(data[6])
        }

        let hasCalibration = (flags & CgmFlag.calibration.rawValue) != 0
        let calibrationByte: UInt8 = hasCalibration ? data[CgmMeasurement.getCalibrationOffset(hasStatus)] : 0
        if hasCalibration {
            statusValues.append(calibrationByte)
        }

        let hasWarning = (flags & CgmFlag.warning.rawValue) != 0
        let warningByte: UInt8 = hasWarning ? data[CgmMeasurement.getWarningOffset(hasStatus, hasCalibration)] : 0
        if hasWarning {
            statusValues.append(warningByte)
        }

        self.statusValues = statusValues

        let annunciation = Data([statusByte, calibrationByte, warningByte])
        let status = SensorStatus.parseStatusAnnunciation(annunciation)

        let decoded = data.getDouble(offset: 2)

        if status.contains(.sensorResultHigherThanDeviceCanProcess) {
            isValid = true
            condition = .aboveRange
            glucoseInMgDl = MeasurableRangeMgDl.high
        } else if status.contains(.sensorResultLowerThanDeviceCanProcess) {
            isValid = true
            condition = .belowRange
            glucoseInMgDl = MeasurableRangeMgDl.low
        } else if !status.contains(.sensorMalfunction), decoded.isFinite {
            isValid = true
            condition = nil
            // Clamp before narrowing: a malformed glucose word can decode outside
            // UInt16's range, and an unchecked conversion would trap.
            glucoseInMgDl = UInt16(min(max(decoded, 0), Double(UInt16.max)))
        } else {
            isValid = false
            condition = nil
            glucoseInMgDl = 0
        }

        let hasTrend = (flags & CgmFlag.trend.rawValue) != 0
        if hasTrend {
            trend = data.getDouble(offset: CgmMeasurement.getTrendOffset(hasStatus, hasCalibration, hasWarning))
        } else {
            trend = nil
        }

        let hasQuality = (flags & CgmFlag.quality.rawValue) != 0
        if hasQuality {
            quality = data.getDouble(offset: CgmMeasurement.getQualityOffset(hasStatus, hasCalibration, hasWarning, hasTrend))
        } else {
            quality = nil
        }
    }

    var describe: String {
        "[CgmMeasurement] glucoseInMgDl: \(glucoseInMgDl)mg/dl, timeOffset: \(timeOffset), flags=\(flags), statusValues=\(statusValues.hexString()), trend=\(String(describing: trend)), quality=\(String(describing: quality))"
    }

    func getTrend() -> GlucoseTrend? {
        guard let trend else {
            return nil
        }

        switch trend {
        case _ where trend <= (-3.5):
            return .downDownDown
        case _ where trend <= (-2):
            return .downDown
        case _ where trend <= (-1):
            return .down
        case _ where trend <= 1:
            return .flat
        case _ where trend <= 2:
            return .up
        case _ where trend <= 3.5:
            return .upUp
        default:

            return .flat
        }
    }

    private static func getCalibrationOffset(_ hasStatus: Bool) -> Int {
        6 + (hasStatus ? 1 : 0)
    }

    private static func getWarningOffset(_ hasStatus: Bool, _ hasCalibration: Bool) -> Int {
        getCalibrationOffset(hasStatus) + (hasCalibration ? 1 : 0)
    }

    private static func getTrendOffset(_ hasStatus: Bool, _ hasCalibration: Bool, _ hasWarning: Bool) -> Int {
        getWarningOffset(hasStatus, hasCalibration) + (hasWarning ? 1 : 0)
    }

    private static func getQualityOffset(_ hasStatus: Bool, _ hasCalibration: Bool, _ hasWarning: Bool, _ hasTrend: Bool) -> Int {
        getTrendOffset(hasStatus, hasCalibration, hasWarning) + (hasTrend ? 1 : 0)
    }

    private enum CgmFlag: UInt8 {
        case trend = 1
        case quality = 2
        case warning = 32
        case calibration = 64
        case status = 128
    }
}
