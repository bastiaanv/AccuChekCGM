@testable import AccuChekKit
import Foundation
import Testing

class CgmStartTimeTests {
    @Test func testCorrectCgmMeasurementParsing() async throws {
        // bdf6
        let data = Data(hexString: "ea07020412362c00fffcc8")
        let measurement = CgmStartTime(data)

        print(measurement.describe)
        #expect(measurement.describe != "")
    }
}
