@testable import AccuChekKit
import Foundation
import Testing

class GetCalibrationPacketTests {
    @Test func testResult() async throws {
        let data = Data(hexString: "066f00670211d00201000175e6")
        let packet = GetCalibrationPacket(recordIndex: 0xFFFF)
        
        packet.parseResponse(data: data)
        print(packet.describe)
        #expect(packet.describe != "")
    }
}
