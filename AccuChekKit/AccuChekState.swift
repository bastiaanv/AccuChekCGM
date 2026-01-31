import LoopKit

struct AccuChekState: RawRepresentable, Equatable {
    public typealias RawValue = CGMManager.RawStateValue

    public var onboarded: Bool

    public var isConnected: Bool
    public var mtu: UInt16 = 0
    public var serialNumber: String?
    public var hasAcs: Bool
    
    // Authentication of CGM
    public var pinCode: String?
    public var privateKey: Data?
    public var publicKey: Data?

    public var lastGlucoseTimestamp: Date?
    public var lastGlucoseValue: UInt16?
    
    public var accessToken: String?
    public var expiresAt: Date?
    public var refreshToken: String?

    init(rawValue: CGMManager.RawStateValue) {
        onboarded = rawValue["onboarded"] as? Bool ?? false
        isConnected = false
        mtu = rawValue["mtu"] as? UInt16 ?? 20
        hasAcs = rawValue["hasAcs"] as? Bool ?? true
        serialNumber = rawValue["serialNumber"] as? String
        pinCode = rawValue["pinCode"] as? String
        privateKey = rawValue["privateKey"] as? Data
        publicKey = rawValue["publicKey"] as? Data
        lastGlucoseTimestamp = rawValue["lastGlucoseTimestamp"] as? Date
        lastGlucoseValue = rawValue["lastGlucoseValue"] as? UInt16
        accessToken = rawValue["accessToken"] as? String
        refreshToken = rawValue["refreshToken"] as? String
        expiresAt = rawValue["expiresAt"] as? Date
    }

    var rawValue: CGMManager.RawStateValue {
        var raw: CGMManager.RawStateValue = [:]

        raw["onboarded"] = onboarded
        raw["mtu"] = mtu
        raw["serialNumber"] = serialNumber
        raw["hasAcs"] = hasAcs
        raw["pinCode"] = pinCode
        raw["privateKey"] = privateKey
        raw["publicKey"] = publicKey
        raw["lastGlucoseTimestamp"] = lastGlucoseTimestamp
        raw["lastGlucoseValue"] = lastGlucoseValue
        raw["accessToken"] = accessToken
        raw["refreshToken"] = refreshToken
        raw["expiresAt"] = expiresAt

        return raw
    }

    var debugDescription: String {
        [
            "* onboarded: \(onboarded)",
            "* mtu: \(mtu)",
            "* serialNumber: \(String(describing: serialNumber))",
            "* isConnected: \(isConnected)",
            "* hasAcs: \(hasAcs)",
            "* lastGlucoseTimestamp: \(String(describing: lastGlucoseTimestamp))",
            "* lastGlucoseValue: \(String(describing: lastGlucoseValue))"
        ].joined(separator: "\n")
    }
}
