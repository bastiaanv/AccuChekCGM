enum SecurityControl: UInt8 {
    case Nonce = 0x00
    case Authenticated = 0x01
    case Encrypted = 0x02
    case AuthenticatedAndEncrypted = 0x03
    case AuthenticatedAndEncryptedWithAssociatedData = 0x04
    case Unencrypted = 0x05
    case Mac = 0x06
}
