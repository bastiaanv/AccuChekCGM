@testable import AccuChekKit
import Foundation
import Testing

class CalibratePacketTests {
    @Test func testCorrectCalibratePacket() async throws {
        let packet = CalibratePacket(glucoseInMgDl: 200, cgmStartTime: Date.now.addingTimeInterval(.minutes(-30)))

        print(packet.getRequest().hexString())
        #expect(!packet.getRequest().isEmpty)
    }

    @Test func testCalibrateRequest() async throws {
        let packet = CalibratePacket(glucoseInMgDl: 200, cgmStartTime: Date.now.addingTimeInterval(.minutes(-30)))
        let request = packet.getRequest()

        #expect(request[0] == 0x04) // Calibration opcode
        
        // 200 mg/dL = 0x00C8 = 0xC800 (LE)
        #expect(request[1] == 0xC8)
        #expect(request[2] == 0x00)
    }

    @Test func testRealCalibrateResponseSucceeds() async throws {
        let packet = CalibratePacket(glucoseInMgDl: 200, cgmStartTime: Date.now)
        packet.parseResponse(data: Data(hexString: "1c0401ec6f")) // From real device

        #expect(packet.responseCode == 0x01)
        #expect(packet.isComplete() == true)
    }
}
