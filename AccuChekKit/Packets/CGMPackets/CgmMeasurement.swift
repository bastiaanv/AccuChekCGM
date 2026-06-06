import Foundation
import LoopKit

class CgmMeasurement {
    let flags: UInt8
    let glucoseInMgDl: UInt16
    let timeOffset: TimeInterval
    let statusValues: Data
    let trend: Double?
    let quality: Double?
    let isValid: Bool
    let condition: GlucoseCondition?

    // The sensor is spec'd to 40-400 mg/dL (2.2-22.2 mmol/L). Values at the edges
    // are clamped and reported as LO / HI rather than as a dosable number.
    static let lowThresholdMgDl: UInt16 = 40
    static let highThresholdMgDl: UInt16 = 400
    
    // Sensor Status Annunciation Status octet, bit 3 (0x08) = "Sensor malfunction
    // or faulting at time of measurement" (Bluetooth CGM Service spec). The
    // sensor sets this on the bogus 2047 mg/dL readings it emits on a failed
    // measurement, so the glucose field is garbage and the reading must be dropped.
    static let statusSensorMalfunction: UInt8 = 0x08

    init(_ data: Data) {
        flags = data[1]
        timeOffset = TimeInterval.minutes(Double(data.getUInt16(offset: 4)))

        var statusValues = Data()

        let hasStatus = (flags & CgmFlag.status.rawValue) != 0
        let statusByte: UInt8 = hasStatus ? data[6] : 0
        if hasStatus {
            statusValues.append(data[6])
        }

        // Drop the reading when the sensor reports a malfunction (status bit 0x08 is set).
        isValid = (statusByte & CgmMeasurement.statusSensorMalfunction) == 0

        if isValid {
            // Clamp before narrowing: a malformed glucose word can decode outside
            // UInt16's range, and an unchecked conversion would trap.
            let decoded = data.getDouble(offset: 2)
            let value = UInt16(min(max(decoded, 0), Double(UInt16.max)))
            
            if value <= CgmMeasurement.lowThresholdMgDl {
                condition = .belowRange
                glucoseInMgDl = CgmMeasurement.lowThresholdMgDl
            } else if value >= CgmMeasurement.highThresholdMgDl {
                condition = .aboveRange
                glucoseInMgDl = CgmMeasurement.highThresholdMgDl
            } else {
                condition = nil
                glucoseInMgDl = value
            }
        } else {
            condition = nil
            glucoseInMgDl = 0
        }

        let hasCalibration = (flags & CgmFlag.calibration.rawValue) != 0
        if hasCalibration {
            statusValues.append(data[CgmMeasurement.getCalibrationOffset(hasStatus)])
        }

        let hasWarning = (flags & CgmFlag.warning.rawValue) != 0
        if hasWarning {
            statusValues.append(data[CgmMeasurement.getWarningOffset(hasStatus, hasCalibration)])
        }

        self.statusValues = statusValues

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
