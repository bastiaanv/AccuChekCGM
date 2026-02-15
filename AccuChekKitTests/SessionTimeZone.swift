@testable import AccuChekKit
import Foundation
import Testing

class SessionTimeZoneTests {
    @Test() func amsterdamTimeZone() async throws {
        guard let timeZone = TimeZone(secondsFromGMT: Int(TimeInterval.hours(1))) else {
            throw NSError(domain: "Failed to parse timezone", code: -1)
        }

        let result = SessionTimeZone.fromTimeZone(timeZone: timeZone)
        #expect(result == .utcPlus0100)
    }

    @Test() func utcTimeZone() async throws {
        guard let timeZone = TimeZone(secondsFromGMT: Int(TimeInterval.hours(0))) else {
            throw NSError(domain: "Failed to parse timezone", code: -1)
        }

        let result = SessionTimeZone.fromTimeZone(timeZone: timeZone)
        #expect(result == .utcPlus0000)
    }

    @Test() func negativeTimeZone() async throws {
        guard let timeZone = TimeZone(secondsFromGMT: Int(TimeInterval.hours(-10))) else {
            throw NSError(domain: "Failed to parse timezone", code: -1)
        }

        let result = SessionTimeZone.fromTimeZone(timeZone: timeZone)
        #expect(result == .utcMinus1000)
    }

    @Test() func tirtyMinTimeZone() async throws {
        guard let timeZone = TimeZone(secondsFromGMT: Int(TimeInterval.hours(9.5))) else {
            throw NSError(domain: "Failed to parse timezone", code: -1)
        }

        let result = SessionTimeZone.fromTimeZone(timeZone: timeZone)
        #expect(result == .utcPlus0930)
    }

    @Test() func fortyfiveMinTimeZone() async throws {
        guard let timeZone = TimeZone(secondsFromGMT: Int(TimeInterval.hours(5.75))) else {
            throw NSError(domain: "Failed to parse timezone", code: -1)
        }

        let result = SessionTimeZone.fromTimeZone(timeZone: timeZone)
        #expect(result == .utcPlus0545)
    }
}
