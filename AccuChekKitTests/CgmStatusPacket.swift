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
}
