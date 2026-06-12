@testable import AccuChekKit
import Foundation
import Testing

class SensorStatusPacketTests {
    @Test func testResult() async throws {
        let data = Data(hexString: "6702080a4027e1")
        let packet = SensorStatus(data: data)

        print(packet.describe)
        #expect(packet.describe != "")
    }

    @Test func testAnnunciationBitMapping() async throws {
        let packet = SensorStatus(data: Data(hexString: "6702080a4027e1"))

        #expect(packet.status.contains(.sensorMalfunction))
        #expect(packet.status.contains(.calibrationNotAllowed))
        #expect(packet.status.contains(.calibrationRequired))
        #expect(packet.status.contains(.sensorResultLowerThanDeviceCanProcess))
    }

    // Real device capture. "HI" reading
    @Test func testHiStatusCarriesOutOfRangeBit() async throws {
        let packet = SensorStatus(data: Data(hexString: "0c210802802aa5"))

        #expect(packet.offset == 0x210C)
        #expect(packet.status.contains(.sensorMalfunction))
        #expect(packet.status.contains(.calibrationNotAllowed))
        #expect(packet.status.contains(.sensorResultHigherThanDeviceCanProcess))
    }
}
