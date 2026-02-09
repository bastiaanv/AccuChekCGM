import AccuChekKit
import Foundation
import Testing

class CgmMeasurementTests {
    @Test func testCorrectCgmMeasurementParsing() async throws {
        // bdf6
        let data = Data(hexString: "ea07020412362c00fffcc8")
        let measurement = CgmS(data: data)

        print(measurement.describe)
        #expect(measurement.describe != "")
    }
}
