@testable import AccuChekKit
import Foundation
import Testing

class CalibratePacketTests {
    @Test func testCorrectCalibratePacket() async throws {
        let packet = CalibratePacket(glucoseInMgDl: 200, cgmStartTime: Date.now.addingTimeInterval(.minutes(-30)))

        print(packet.getRequest().hexString())
        #expect(!packet.getRequest().isEmpty)
    }
}
