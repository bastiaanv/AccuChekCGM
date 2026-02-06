import LoopKit

// {\"hdTypeId\":\"303\",\"dcdCertificate\":\"MIICJDCCAcqgAwIBAgIUTBy3ZXD1Uj2BvHNdlsZMcfDiW70wCgYIKoZIzj0EAwIwOzEhMB8GA1UECgwYUm9jaGUgRGlhYmV0ZXMgQ2FyZSBHbWJIMRYwFAYDVQQDDA1ISUFNQ0IgQ0EgUHJvMB4XDTI2MDIwNDE5MzMwMloXDTI3MDIwNDE5MzMwMlowgYYxITAfBgNVBAoMGFJvY2hlIERpYWJldGVzIENhcmUgR21iSDEMMAoGA1UEAwwDOTQ3MS0wKwYDVQQFEyRBRTRERjlGMy0yNEZBLTRCMkUtQTc1NC04NzI2M0UxRTk1RDkxDDAKBgNVBAQMAzMwMzEKMAgGA1UEKgwBKjEKMAgGA1UEQQwBKjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABE4AlpEV8hFRfFQiIncmDHHrozsDA4OX9uzsu8fo8CHwKEqk8mLgNz9UfO/lrBycvZyys6IAqncAJpreJL1izEujYDBeMAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgPIMB0GA1UdDgQWBBSogz8KUmOz9fWzqb3M2YTzdcr/7zAfBgNVHSMEGDAWgBT/EpeiDN1nIBPSPn+MQPbvRH9JGzAKBggqhkjOPQQDAgNIADBFAiEAwEuLltsBxRORPPbC6RqP3ODtdk90s4wVOH8LLmFU28YCIHsxplrJBHSCbVBGrU04SxeJ97ZPt3yAQxhgPg1TnnGi\",\"dcdCertificateValidFrom\":\"2026-02-04T19:33:02Z\",\"dcdCertificateValidTo\":\"2027-02-04T19:33:02Z\",\"caSerialNumber\":\"3449c39de3f33f7eb2f809a7b15fe00ee43c3fc8\"}
struct AccuChekState: RawRepresentable, Equatable {
    public typealias RawValue = CGMManager.RawStateValue

    public var onboarded: Bool

    public var isConnected: Bool
    public var mtu: UInt16 = 0
    public var deviceName: String?
    public var serialNumber: String?
    public var certificate: Certificate?

    // Authentication of CGM
    public var pinCode: String?
    public var keyAgreementPrivate: Data?
    public var aesKey: Data?
    public var aesNonce: Data?

    public var lastGlucoseTimestamp: Date?
    public var lastGlucoseValue: UInt16?

    public var accessToken: String?
    public var expiresAt: Date?
    public var refreshToken: String?

    init(rawValue: CGMManager.RawStateValue) {
        onboarded = rawValue["onboarded"] as? Bool ?? false
        isConnected = false
        mtu = rawValue["mtu"] as? UInt16 ?? 20
        deviceName = rawValue["deviceName"] as? String
        serialNumber = rawValue["serialNumber"] as? String
        pinCode = rawValue["pinCode"] as? String
        keyAgreementPrivate = rawValue["keyAgreementPrivate"] as? Data
        aesKey = rawValue["aesKey"] as? Data
        aesNonce = rawValue["aesNonce"] as? Data
        lastGlucoseTimestamp = rawValue["lastGlucoseTimestamp"] as? Date
        lastGlucoseValue = rawValue["lastGlucoseValue"] as? UInt16
        accessToken = rawValue["accessToken"] as? String
        refreshToken = rawValue["refreshToken"] as? String
        expiresAt = rawValue["expiresAt"] as? Date

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
        raw["lastGlucoseTimestamp"] = lastGlucoseTimestamp
        raw["lastGlucoseValue"] = lastGlucoseValue
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
            "* lastGlucoseTimestamp: \(String(describing: lastGlucoseTimestamp))",
            "* lastGlucoseValue: \(String(describing: lastGlucoseValue))"
        ].joined(separator: "\n")
    }
}
