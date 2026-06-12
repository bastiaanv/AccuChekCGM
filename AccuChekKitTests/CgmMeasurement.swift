@testable import AccuChekKit
import Foundation
import LoopKit
import Testing

class CgmMeasurementTests {
    @Test func testCorrectCgmMeasurementParsing() async throws {
        // bdf6
        let data = Data(hexString: "0d43bdf62c0602fcff5f006d57")
        let measurement = CgmMeasurement(data)

        print(measurement.describe)
        #expect(measurement.describe != "")
    }

    @Test func testCrash() async throws {
        let data = Data(hexString: "0fe302086801080a40faff5400c492")
        let measurement = CgmMeasurement(data)

        print(measurement.describe)
        #expect(measurement.describe != "")
    }

    // Real device capture. Glucose above the device's measurable range.
    // Warning byte 0x80 set ("higher than device can process")
    // Malfunction bit set bit (0x08).
    // Must be clamped to 400 (HI/aboveRange), not dropped as a malfunction.
    @Test func testDeviceHiSurfacesAsAboveRange() async throws {
        let data = Data(hexString: "0fe3fe07ee20080280f5e0620047b3")
        let measurement = CgmMeasurement(data)

        #expect(measurement.isValid == true)
        #expect(measurement.condition == .aboveRange)
        #expect(measurement.glucoseInMgDl == 400)
    }

    // Real device capture. Genuine sensor malfunction.
    // Malfunction bit set (0x08)
    // No out-of-range warning byte
    // Glucose word is the 0x07FF "value not available" sentinel
    // Reading is logged as 2047 mg/dL, which is wrong and should be dropped.
    @Test func testDeviceMalfunctionSentinelIsDropped() async throws {
        let data = Data(hexString: "0ec3ff0772060802ff07ff075ad4")
        let measurement = CgmMeasurement(data)

        #expect(measurement.isValid == false)
        #expect(measurement.condition == nil)
    }
}
