enum DstOffset: UInt8 {
    case standardTime = 0
    case halfAnHourDaylightTimePlus05H = 2
    case daylightTimePlus1H = 4
    case doubleDaylightTimePlus2H = 8
    case reserved = 9
    case dstIsNotKnown = 255
}
