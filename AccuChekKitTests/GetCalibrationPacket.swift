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

    // Real device capture. Response after calibration has been accepted.
    @Test func testFirstCalibrationResonse() async throws {
        let packet = GetCalibrationPacket(recordIndex: 0xFFFF)
        packet.parseResponse(data: Data(hexString: "0698f3380411ec04010000f07d"))

        // Calibration accepted. Next one due in 1260 minutes.
        #expect(packet.receivedResponse == true)
        #expect(packet.nextCalibrationOffset == 1260)
        #expect(packet.recordNumber == 1)
        #expect(packet.calibrationStatus == 0)
    }

    // Real device capture. Response after all calibrations are completed.
    @Test func testCalibrationsComplete() async throws {
        let packet = GetCalibrationPacket(recordIndex: 0xFFFF)
        packet.parseResponse(data: Data(hexString: "06e4f2710411ffff02000000fe"))

        #expect(packet.receivedResponse == true)
      
        // Second calibration
        #expect(packet.recordNumber == 2)
        
        // Sentinel value indicating "not scheduled" (sensor fully calibrated)
        #expect(packet.nextCalibrationOffset == 0xFFFF)
    }
}
