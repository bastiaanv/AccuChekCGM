import Foundation

protocol IKeyDescriptor {
    var keyId: UInt16 { get }
}

class EcdhKeyDescriptor : IKeyDescriptor {
    let keyId: UInt16
    let serverPublicKeyFormat: PublicKeyFormat
    let clientPublicKeyFormat: PublicKeyFormat
    let ellipticCurve: EllipticCurveType
    let keyDerivationFunction: KeyDerivationFunctionType
    
    init?(keyId: UInt16, serverPublicKeyFormat: UInt8, clientPublicKeyFormat: UInt8, ellipticCurve: UInt8, keyDerivationFunction: UInt8) {
        guard
            let serverPublicKeyFormat = PublicKeyFormat(rawValue: serverPublicKeyFormat),
            let clientPublicKeyFormat = PublicKeyFormat(rawValue: clientPublicKeyFormat),
            let ellipticCurve = EllipticCurveType(rawValue: ellipticCurve),
            let keyDerivationFunction = KeyDerivationFunctionType(rawValue: keyDerivationFunction)
        else {
            return nil
        }
        
        self.keyId = keyId
        self.serverPublicKeyFormat = serverPublicKeyFormat
        self.clientPublicKeyFormat = clientPublicKeyFormat
        self.ellipticCurve = ellipticCurve
        self.keyDerivationFunction = keyDerivationFunction
    }
}

class AesCgmKeyDescriptor : IKeyDescriptor {
    let keyId: UInt16
    let keyType: KeyDescriptorType
    let messageType: MessageType
    let macSize: UInt8
    let nonceType: NonceType
    let nonceVariableSize: UInt8
    let nonceFixedSize: UInt8
    let nonceFixedValue: Data
    
    init?(keyId: UInt16, keyType: UInt8, messageType: UInt8, macSize: UInt8, nonceType: UInt8, nonceVariableSize: UInt8, nonceFixedSize: UInt8, nonceFixedValue: Data) {
        guard
            let keyType = KeyDescriptorType(rawValue: keyType),
            let messageType = MessageType(rawValue: messageType),
            let nonceType = NonceType(rawValue: nonceType)
        else {
            return nil
        }
        
        self.keyId = keyId
        self.keyType = keyType
        self.messageType = messageType
        self.macSize = macSize
        self.nonceType = nonceType
        self.nonceVariableSize = nonceVariableSize
        self.nonceFixedSize = nonceFixedSize
        self.nonceFixedValue = nonceFixedValue
    }
}

enum MessageType : UInt8 {
    case profileDefinedParameter = 0x00
    case protectedResourceValue = 0x01
}

enum NonceType : UInt8 {
    case profileDefined = 0x00
    case sequenceNumberEvenOdd = 0x01
    case sequenceNumberDifferentFixedParts = 0x02
}

enum PublicKeyFormat: UInt8 {
    case uncompressedPlain = 0x00
    case x509DerEncoded = 0x01
}

enum EllipticCurveType : UInt8 {
    case curveP256 = 0x00
    case curveP384 = 0x01
    case curveP521 = 0x02
    case curve25519 = 0x03
}

enum KeyDerivationFunctionType: UInt8 {
    case hkdfSha256128Bit = 0x00
    case hkdfSha256128BitWithAdditionalInfo = 0x01
    case hkdfSha384128Bit = 0x02
    case hkdfSha384128BitWithAdditionalInfo = 0x03
    case hkdfSha512128Bit = 0x04
    case hkdfSha512128BitWithAdditionalInfo = 0x05
}
