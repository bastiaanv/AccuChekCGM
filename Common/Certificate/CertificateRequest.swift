// Source: https://github.com/cbaker6/CertificateSigningRequest
import CryptoKit
import Foundation

public enum SubjectItem {
    case commonName(String)
    case surName(String)
    case givenName(String)
    case organizationName(String)
    case organizationUnitName(String)
    case countryName(String)
    case stateOrProvinceName(String)
    case serialNumber(String)
    case localityName(String)
    case description(String)
    case pseudonym(String)
    case emailAddress(String)

    func getObjectKey() -> [UInt8] {
        switch self {
        case .commonName:
            return [0x06, 0x03, 0x55, 0x04, 0x03]
        case .surName:
            return [0x06, 0x03, 0x55, 0x04, 0x04]
        case .givenName:
            return [0x06, 0x03, 0x55, 0x04, 0x2A]
        case .organizationName:
            return [0x06, 0x03, 0x55, 0x04, 0x0A]
        case .organizationUnitName:
            return [0x06, 0x03, 0x55, 0x04, 0x0B]
        case .countryName:
            return [0x06, 0x03, 0x55, 0x04, 0x06]
        case .stateOrProvinceName:
            return [0x06, 0x03, 0x55, 0x04, 0x08]
        case .serialNumber: // 06 03 55
            return [0x06, 0x03, 0x55, 0x04, 0x05]
        case .localityName:
            return [0x06, 0x03, 0x55, 0x04, 0x07]
        case .description:
            return [0x06, 0x03, 0x55, 0x04, 0x0D]
        case .pseudonym:
            return [0x06, 0x03, 0x55, 0x04, 0x41]
        case .emailAddress:
            return [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x09, 0x01]
        }
    }

    func getValue() -> String {
        switch self {
        case let .commonName(value):
            return value
        case let .surName(value):
            return value
        case let .givenName(value):
            return value
        case let .organizationName(value):
            return value
        case let .organizationUnitName(value):
            return value
        case let .countryName(value):
            return value
        case let .stateOrProvinceName(value):
            return value
        case let .serialNumber(value):
            return value
        case let .localityName(value):
            return value
        case let .description(value):
            return value
        case let .pseudonym(value):
            return value
        case let .emailAddress(value):
            return value
        }
    }
}

// swiftlint:disable:next type_body_length
public class CertificateSigningRequest: NSObject {
    private let sequenceTag: UInt8 = 0x30
    private let setTag: UInt8 = 0x31
    private var subjectItems: [SubjectItem] = []
    private let keyAlgorithm: KeyAlgorithm
    private var subjectDER: Data?

    public init(keyAlgorithm: KeyAlgorithm) {
        self.keyAlgorithm = keyAlgorithm
        super.init()
    }

    override public convenience init() {
        self.init(keyAlgorithm: KeyAlgorithm.ec(signatureType: .sha256))
    }

    public convenience init(
        commonName: String? = nil,
        surName: String? = nil,
        givenName: String? = nil,
        organizationName: String? = nil,
        organizationUnitName: String? = nil,
        countryName: String? = nil,
        stateOrProvinceName: String? = nil,
        localityName: String? = nil,
        serialNumber: String? = nil,
        pseudonym: String? = nil,
        emailAddress: String? = nil,
        description: String? = nil,
        keyAlgorithm: KeyAlgorithm
    ) {
        self.init(keyAlgorithm: keyAlgorithm)

        if let organizationName = organizationName {
            addSubjectItem(.organizationName(organizationName))
        }
        if let commonName = commonName {
            addSubjectItem(.commonName(commonName))
        }
        if let serialNumber = serialNumber {
            addSubjectItem(.serialNumber(serialNumber))
        }
        if let surName = surName {
            addSubjectItem(.surName(surName))
        }
        if let givenName = givenName {
            addSubjectItem(.givenName(givenName))
        }
        if let organizationUnitName = organizationUnitName {
            addSubjectItem(.organizationUnitName(organizationUnitName))
        }
        if let countryName = countryName {
            addSubjectItem(.countryName(countryName))
        }
        if let stateOrProvinceName = stateOrProvinceName {
            addSubjectItem(.stateOrProvinceName(stateOrProvinceName))
        }
        if let localityName = localityName {
            addSubjectItem(.localityName(localityName))
        }
        if let emailAddress = emailAddress {
            addSubjectItem(.emailAddress(emailAddress))
        }
        if let description = description {
            addSubjectItem(.description(description))
        }
        if let pseudonym = pseudonym {
            addSubjectItem(.pseudonym(pseudonym))
        }
    }

    public func addSubjectItem(_ subjectItem: SubjectItem) {
        subjectItems.append(subjectItem)
    }

    public func build(privateKey: P256.KeyAgreement.PrivateKey) -> Data? {
        let certificationRequestInfo = buildCertificationRequestInfo(privateKey)

        do {
            let signingKey = try P256.Signing.PrivateKey(derRepresentation: privateKey.derRepresentation)
            let signature = try signingKey.signature(for: certificationRequestInfo)

            var signData = Data(capacity: 257)
            signData.append(0)
            signData.append(signature.derRepresentation)

            var certificationRequest = Data(capacity: 1024)
            certificationRequest.append(certificationRequestInfo)
            let shaBytes = keyAlgorithm.sequenceObjectEncryptionType
            certificationRequest.append(shaBytes, count: shaBytes.count)
            appendBITSTRING(signData, into: &certificationRequest)

            enclose(&certificationRequest, by: sequenceTag) // Enclose into SEQUENCE

            return certificationRequest
        } catch {
            print("Error while generating signature: \(error.localizedDescription)")
            return nil
        }
    }

    public func buildAndEncodeDataAsString(privateKey: P256.KeyAgreement.PrivateKey) -> String? {
        guard let buildData = build(privateKey: privateKey) else {
            print("Failed to do Build")
            return nil
        }

        return buildData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
    }

    public func buildCSRAndReturnString(privateKey: P256.KeyAgreement.PrivateKey) -> String? {
        guard let csrString = buildAndEncodeDataAsString(privateKey: privateKey) else {
            return nil
        }

        let head = "-----BEGIN CERTIFICATE REQUEST-----\n"
        let foot = "-----END CERTIFICATE REQUEST-----\n"
        var isMultiple = false
        var newCSRString = head

        // Check if string size is a multiple of 64
        if csrString.count % 64 == 0 {
            isMultiple = true
        }

        for (integer, character) in csrString.enumerated() {
            newCSRString.append(character)

            if integer != 0, (integer + 1) % 64 == 0 {
                newCSRString.append("\n")
            }

            if integer == csrString.count - 1, !isMultiple {
                newCSRString.append("\n")
            }
        }

        newCSRString += foot

        return newCSRString
    }

    func buildCertificationRequestInfo(_ privateKey: P256.KeyAgreement.PrivateKey) -> Data {
        var certificationRequestInfo = Data(capacity: 256)

        // Add version
        let version: [UInt8] = [0x02, 0x01, 0x00] // ASN.1 Representation of integer with value 1
        certificationRequestInfo.append(version, count: version.count)

        // Add subject
        var subject = Data(capacity: 256)

        for subjectItem in subjectItems {
            switch subjectItem {
            case let .emailAddress(emailAddress):
                appendSubjectItemEmail(subjectItem.getObjectKey(), value: emailAddress, into: &subject)
            case .serialNumber:
                appendSerialItem(subjectItem.getObjectKey(), value: subjectItem.getValue(), into: &subject)
            default:
                appendSubjectItem(subjectItem.getObjectKey(), value: subjectItem.getValue(), into: &subject)
            }
        }

        enclose(&subject, by: sequenceTag) // Enclose into SEQUENCE
        subjectDER = subject
        certificationRequestInfo.append(subject)

        // Add public key info
        let publicKeyInfo = buildPublicKeyInfo(privateKey)
        certificationRequestInfo.append(publicKeyInfo)

        // Add attributes
        let attributes =
            Data(hexString: "a02f302d06092a864886f70d01090e3120301e300c0603551d130101ff04023000300e0603551d0f0101ff0404030203c8")
        certificationRequestInfo.append(attributes)
        enclose(&certificationRequestInfo, by: sequenceTag) // Enclose into SEQUENCE

        return certificationRequestInfo
    }

    func buildPublicKeyInfo(_ privateKey: P256.KeyAgreement.PrivateKey) -> Data {
        var publicKeyInfo = Data(capacity: 390)
        publicKeyInfo.append(objectECPubicKey, count: objectECPubicKey.count)
        publicKeyInfo.append(objectECEncryptionNULL, count: objectECEncryptionNULL.count)

        enclose(&publicKeyInfo, by: sequenceTag) // Enclose into SEQUENCE

        let key = privateKey.publicKey.derRepresentation
        let publicKey = key.subdata(in: 25 ..< key.count)
        appendBITSTRING(publicKey, into: &publicKeyInfo)

        enclose(&publicKeyInfo, by: sequenceTag) // Enclose into SEQUENCE

        return publicKeyInfo
    }

    func appendSerialItem(_ what: [UInt8], value: String, into: inout Data) {
        if what.count != 5, what.count != 11 {
            print("Error: appending to a non-subject item")
            return
        }

        var subjectItem = Data(capacity: 128)

        subjectItem.append(what, count: what.count)
        appendPrintableString(string: value, into: &subjectItem)
        enclose(&subjectItem, by: sequenceTag)
        enclose(&subjectItem, by: setTag)

        into.append(subjectItem)
    }

    func appendSubjectItem(_ what: [UInt8], value: String, into: inout Data) {
        if what.count != 5, what.count != 11 {
            print("Error: appending to a non-subject item")
            return
        }

        var subjectItem = Data(capacity: 128)

        subjectItem.append(what, count: what.count)
        appendUTF8String(string: value, into: &subjectItem)
        enclose(&subjectItem, by: sequenceTag)
        enclose(&subjectItem, by: setTag)

        into.append(subjectItem)
    }

    func appendSubjectItemEmail(_ what: [UInt8], value: String, into: inout Data) {
        if what.count != 5, what.count != 11 {
            print("Error: appending to a non-subject item")
            return
        }

        var subjectItem = Data(capacity: 128)

        subjectItem.append(what, count: what.count)
        appendIA5String(string: value, into: &subjectItem)
        enclose(&subjectItem, by: sequenceTag)
        enclose(&subjectItem, by: setTag)

        into.append(subjectItem)
    }

    func appendUTF8String(string: String, into: inout Data) {
        let strType: UInt8 = 0x0C // UTF8STRING

        into.append(strType)
        appendDERLength(string.lengthOfBytes(using: String.Encoding.utf8), into: &into)
        into.append(string.data(using: String.Encoding.utf8)!)
    }

    func appendPrintableString(string: String, into: inout Data) {
        let strType: UInt8 = 0x13 // PrintableString

        into.append(strType)
        appendDERLength(string.lengthOfBytes(using: String.Encoding.utf8), into: &into)
        into.append(string.data(using: String.Encoding.utf8)!)
    }

    func appendIA5String(string: String, into: inout Data) {
        let strType: UInt8 = 0x16 // IA5String

        into.append(strType)
        appendDERLength(string.lengthOfBytes(using: String.Encoding.utf8), into: &into)
        into.append(string.data(using: String.Encoding.utf8)!)
    }

    func appendDERLength(_ length: Int, into: inout Data) {
        assert(length < 0x8000)

        if length < 128 {
            let dLength = UInt8(length)
            into.append(dLength)

        } else if length < 0x100 {
            var dLength: [UInt8] = [0x81, UInt8(length & 0xFF)]
            into.append(&dLength, count: dLength.count)

        } else if length < 0x8000 {
            let preRes = UInt(length & 0xFF00)
            let res = UInt8(preRes >> 8)
            var dLength: [UInt8] = [0x82, res, UInt8(length & 0xFF)]
            into.append(&dLength, count: dLength.count)
        }
    }

    func appendBITSTRING(_ data: Data, into: inout Data) {
        let strType: UInt8 = 0x03 // BIT STRING
        into.append(strType)
        appendDERLength(data.count, into: &into)
        into.append(data)
    }

    func enclose(_ data: inout Data, by: UInt8) {
        var newData = Data(capacity: data.count + 4)

        newData.append(by)
        appendDERLength(data.count, into: &newData)
        newData.append(data)

        data = newData
    }

    func prependByte(_ byte: UInt8, into: inout Data) {
        var newData = Data(capacity: into.count + 1)

        newData.append(byte)
        newData.append(into)

        into = newData
    }

    func getPublicKeyExp(_ publicKeyBits: Data) -> Data {
        var iterator = 0

        iterator += 1 // TYPE - bit stream - mod + exp
        _ = derEncodingGetSizeFrom(publicKeyBits, at: &iterator) // Total size

        iterator += 1 // TYPE - bit stream mod
        let modSize = derEncodingGetSizeFrom(publicKeyBits, at: &iterator)
        iterator += modSize

        iterator += 1 // TYPE - bit stream exp
        let expSize = derEncodingGetSizeFrom(publicKeyBits, at: &iterator)

        let range: Range<Int> = iterator ..< (iterator + expSize)

        return publicKeyBits.subdata(in: range)
    }

    func getPublicKeyMod(_ publicKeyBits: Data) -> Data {
        var iterator = 0

        iterator += 1 // TYPE - bit stream - mod + exp
        _ = derEncodingGetSizeFrom(publicKeyBits, at: &iterator)

        iterator += 1 // TYPE - bit stream mod
        let modSize = derEncodingGetSizeFrom(publicKeyBits, at: &iterator)

        let range: Range<Int> = iterator ..< (iterator + modSize)

        return publicKeyBits.subdata(in: range)
    }

    func derEncodingGetSizeFrom(_ buf: Data, at iterator: inout Int) -> Int {
        var data = [UInt8](repeating: 0, count: buf.count)
        buf.copyBytes(to: &data, count: buf.count)

        var itr = iterator
        var numOfBytes = 1
        var ret = 0

        if data[itr] > 0x80 {
            numOfBytes = Int(data[itr] - 0x80)
            itr += 1
        }

        for index in 0 ..< numOfBytes {
            ret = (ret * 0x100) + Int(data[itr + index])
        }

        iterator = itr + numOfBytes

        return ret
    }
}
