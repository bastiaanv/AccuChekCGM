@testable import AccuChekKit
import Foundation
import Testing

class CalibratePacketTests {
    @Test func testCorrectCalibratePacket() async throws {
        let packet = CalibratePacket(glucoseInMgDl: 100, cgmStartTime: Date.now.addingTimeInterval(.minutes(-30)))

        print(packet.getRequest().hexString())
        #expect(!packet.getRequest().isEmpty)
    }
}
