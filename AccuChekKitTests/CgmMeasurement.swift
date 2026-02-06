import AccuChekKit
import Foundation
import Testing

class CgmMeasurementTests {
    @Test func testCorrectCgmMeasurementParsing() async throws {
        // bdf6
        let data = Data(hexString: "0d43bdf62c0602fcff5f006d57")
        let measurement = CgmMeasurement(data: data)

        print(measurement.describe)
        #expect(measurement.describe != "")
    }
}
