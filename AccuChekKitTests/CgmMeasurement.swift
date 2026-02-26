@testable import AccuChekKit
import Foundation
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
}
