enum KeyDescriptorType: UInt8 {
    case oobKeyExchange = 0
    case ecdhKeyExchange = 1
    case kdfKeyExchange = 2
    case aes128Cmac = 3
    case aes128Ccm = 4
    case aes128Eax = 5
    case aes128Gcm = 6
    case aes128Gmac = 7
    case manufacturerSpecific = 15
}
