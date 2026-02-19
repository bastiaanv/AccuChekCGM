import HealthKit
import LoopKit

public struct GlucoseDisplay: GlucoseDisplayable {
    public let isStateValid: Bool
    public let trendType: LoopKit.GlucoseTrend?
    public let trendRate: HKQuantity? = nil
    public let isLocal: Bool = true
    public let glucoseRangeCategory: LoopKit.GlucoseRangeCategory? = nil

    init(state: AccuChekState) {
        if let lastSynced = state.lastGlucoseDate {
            isStateValid = abs(lastSynced.timeIntervalSinceNow) <= TimeInterval(minutes: 15)
        } else {
            isStateValid = false
        }

        trendType = state.lastGlucoseTrend
    }
}

struct AccuChekState: RawRepresentable, Equatable {
    public typealias RawValue = CGMManager.RawStateValue

    public var onboarded: Bool

    public var isConnected: Bool
    public var mtu: UInt16 = 0
    public var deviceName: String?
    public var previousDeviceName: String?
    public var serialNumber: String?
    public var certificate: Certificate?

    public var cgmStatus: [SensorStatusEnum]
    public var cgmStatusTimestamp: Date?

    // Authentication of CGM
    public var pinCode: String?
    public var keyAgreementPrivate: Data?
    public var aesKey: Data?
    public var aesNonce: Data?

    public var cgmStartTime: Date?
    public var cgmEndTime: Date? {
        guard let cgmStartTime else {
            return nil
        }

        return cgmStartTime.addingTimeInterval(.days(14))
    }

    public var lastGlucoseOffset: TimeInterval?
    public var lastGlucoseDate: Date?
    public var lastGlucoseValue: UInt16?
    public var lastGlucoseTrend: GlucoseTrend?

    public var nextCalibrationAt: Date?

    public var accessToken: String?
    public var expiresAt: Date?
    public var refreshToken: String?

    init(rawValue: CGMManager.RawStateValue) {
        onboarded = rawValue["onboarded"] as? Bool ?? false
        isConnected = false
        mtu = rawValue["mtu"] as? UInt16 ?? 20
        deviceName = rawValue["deviceName"] as? String
        serialNumber = rawValue["serialNumber"] as? String
        cgmStatusTimestamp = rawValue["cgmStatusTimestamp"] as? Date
        pinCode = rawValue["pinCode"] as? String
        keyAgreementPrivate = rawValue["keyAgreementPrivate"] as? Data
        aesKey = rawValue["aesKey"] as? Data
        aesNonce = rawValue["aesNonce"] as? Data
        cgmStartTime = rawValue["cgmStartTime"] as? Date
        lastGlucoseOffset = rawValue["lastGlucoseOffset"] as? TimeInterval
        lastGlucoseDate = rawValue["lastGlucoseDate"] as? Date
        lastGlucoseValue = rawValue["lastGlucoseValue"] as? UInt16
        nextCalibrationAt = rawValue["nextCalibrationAt"] as? Date
        accessToken = rawValue["accessToken"] as? String
        refreshToken = rawValue["refreshToken"] as? String
        expiresAt = rawValue["expiresAt"] as? Date

        if let rawLastGlucoseTrend = rawValue["lastGlucoseTrend"] as? GlucoseTrend.RawValue {
            lastGlucoseTrend = GlucoseTrend(rawValue: rawLastGlucoseTrend) ?? .flat
        } else {
            lastGlucoseTrend = .flat
        }

        if let rawCgmStatus = rawValue["cgmStatus"] as? [SensorStatusEnum.RawValue] {
            cgmStatus = rawCgmStatus.compactMap { SensorStatusEnum(rawValue: $0) }
        } else {
            cgmStatus = []
        }

        do {
            if let certificateRaw = rawValue["certificate"] as? Data {
                certificate = try JSONDecoder().decode(Certificate.self, from: certificateRaw)
            } else {
                certificate = nil
            }
        } catch {
            certificate = nil
        }
    }

    var rawValue: CGMManager.RawStateValue {
        var raw: CGMManager.RawStateValue = [:]

        raw["onboarded"] = onboarded
        raw["mtu"] = mtu
        raw["deviceName"] = deviceName
        raw["serialNumber"] = serialNumber
        raw["pinCode"] = pinCode
        raw["keyAgreementPrivate"] = keyAgreementPrivate
        raw["aesKey"] = aesKey
        raw["aesNonce"] = aesNonce
        raw["cgmStatus"] = cgmStatus.map(\.rawValue)
        raw["cgmStatusTimestamp"] = cgmStatusTimestamp
        raw["cgmStartTime"] = cgmStartTime
        raw["lastGlucoseOffset"] = lastGlucoseOffset
        raw["lastGlucoseDate"] = lastGlucoseDate
        raw["lastGlucoseValue"] = lastGlucoseValue
        raw["lastGlucoseTrend"] = lastGlucoseTrend?.rawValue
        raw["nextCalibrationAt"] = nextCalibrationAt
        raw["accessToken"] = accessToken
        raw["refreshToken"] = refreshToken
        raw["expiresAt"] = expiresAt

        do {
            raw["certificate"] = try JSONEncoder().encode(certificate)
        } catch {}

        return raw
    }

    var debugDescription: String {
        [
            "* onboarded: \(onboarded)",
            "* mtu: \(mtu)",
            "* deviceName: \(String(describing: deviceName))",
            "* serialNumber: \(String(describing: serialNumber))",
            "* isConnected: \(isConnected)",
            "* cgmStartTime: \(String(describing: cgmStartTime))",
            "* cgmStatus: \(String(describing: cgmStatus))",
            "* cgmStatusTimestamp: \(String(describing: cgmStatusTimestamp))",
            "* lastGlucoseOffset: \(String(describing: lastGlucoseOffset?.minutes))",
            "* lastGlucoseDate: \(String(describing: lastGlucoseDate))",
            "* lastGlucoseValue: \(String(describing: lastGlucoseValue))",
            "* lastGlucoseTrend: \(String(describing: lastGlucoseTrend))",
            "* nextCalibrationAt: \(String(describing: nextCalibrationAt))"
        ].joined(separator: "\n")
    }
}
