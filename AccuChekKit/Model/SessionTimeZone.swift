import Foundation

enum SessionTimeZone: UInt8 {
    case timeOffsetNotKnown = 128 // sbyte.MinValue (-128)

    case utcMinus1200 = 208 // -48
    case utcMinus1100 = 212 // -44
    case utcMinus1000 = 216 // -40
    case utcMinus0930 = 218 // -38
    case utcMinus0900 = 220 // -36
    case utcMinus0800 = 224 // -32
    case utcMinus0700 = 228 // -28
    case utcMinus0600 = 232 // -24
    case utcMinus0500 = 236 // -20
    case utcMinus0430 = 238 // -18
    case utcMinus0400 = 240 // -16
    case utcMinus0330 = 242 // -14
    case utcMinus0300 = 244 // -12
    case utcMinus0200 = 248 // -8
    case utcMinus0100 = 252 // -4

    case utcPlus0000 = 0
    case utcPlus0100 = 4
    case utcPlus0200 = 8
    case utcPlus0300 = 12
    case utcPlus0330 = 14
    case utcPlus0400 = 16
    case utcPlus0430 = 18
    case utcPlus0500 = 20
    case utcPlus0530 = 22
    case utcPlus0545 = 23
    case utcPlus0600 = 24
    case utcPlus0630 = 26
    case utcPlus0700 = 28
    case utcPlus0800 = 32
    case utcPlus0845 = 35
    case utcPlus0900 = 36
    case utcPlus0930 = 38
    case utcPlus1000 = 40
    case utcPlus1030 = 42
    case utcPlus1100 = 44
    case utcPlus1130 = 46
    case utcPlus1200 = 48
    case utcPlus1245 = 51
    case utcPlus1300 = 52
    case utcPlus1400 = 56

    var timeZone: TimeZone? {
        switch self {
        case .utcMinus1200: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-12)))
        case .utcMinus1100: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-11)))
        case .utcMinus1000: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-10)))
        case .utcMinus0930: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-9.5)))
        case .utcMinus0900: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-9)))
        case .utcMinus0800: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-8)))
        case .utcMinus0700: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-7)))
        case .utcMinus0600: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-6)))
        case .utcMinus0500: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-5)))
        case .utcMinus0430: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-4.5)))
        case .utcMinus0400: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-4)))
        case .utcMinus0330: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-3.5)))
        case .utcMinus0300: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-3)))
        case .utcMinus0200: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-2)))
        case .utcMinus0100: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(-1)))
        case .utcPlus0000: return TimeZone(secondsFromGMT: 0)
        case .utcPlus0100: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(1)))
        case .utcPlus0200: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(2)))
        case .utcPlus0300: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(3)))
        case .utcPlus0330: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(3.5)))
        case .utcPlus0400: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(4)))
        case .utcPlus0430: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(4.5)))
        case .utcPlus0500: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(5)))
        case .utcPlus0530: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(5.5)))
        case .utcPlus0545: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(5.75)))
        case .utcPlus0600: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(6)))
        case .utcPlus0630: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(6.5)))
        case .utcPlus0700: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(7)))
        case .utcPlus0800: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(8)))
        case .utcPlus0845: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(8.75)))
        case .utcPlus0900: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(9)))
        case .utcPlus0930: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(9.5)))
        case .utcPlus1000: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(10)))
        case .utcPlus1030: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(10.5)))
        case .utcPlus1100: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(11)))
        case .utcPlus1130: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(11.5)))
        case .utcPlus1200: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(12)))
        case .utcPlus1245: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(12.75)))
        case .utcPlus1300: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(13)))
        case .utcPlus1400: return TimeZone(secondsFromGMT: Int(TimeInterval.hours(14)))

        default: return nil
        }
    }
    
    static func fromTimeZone(timeZone: TimeZone) -> SessionTimeZone? {
        let index = TimeInterval(seconds: Double(timeZone.secondsFromGMT())) / .minutes(15)
        return SessionTimeZone(rawValue: UInt8(bitPattern: Int8(index)))
    }
}
