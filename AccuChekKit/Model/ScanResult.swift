import CoreBluetooth

class ScanResult {
    private let logger = AccuChekLogger(category: "ScanResult")

    public let deviceName: String
    public let peripheral: CBPeripheral

    var describe: String {
        "[ScanResult] deviceName=\(deviceName), peripheral=\(peripheral)"
    }

    init?(peripheral: CBPeripheral, advertismentData _: [String: Any]) {
        guard let deviceName = peripheral.name else {
            logger.error("Empty device name")
            return nil
        }

        self.deviceName = deviceName
        self.peripheral = peripheral
    }
}
