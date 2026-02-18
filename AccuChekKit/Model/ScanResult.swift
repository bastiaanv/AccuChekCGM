import CoreBluetooth

class ScanResult {
    private let logger = AccuChekLogger(category: "ScanResult")

    public let deviceName: String
    public let peripheral: CBPeripheral
    public let hasAcsSupport: Bool

    var describe: String {
        "[ScanResult] deviceName=\(deviceName), peripheral=\(peripheral)"
    }

    init?(peripheral: CBPeripheral, advertismentData: [String: Any]) {
        guard let deviceName = peripheral.name else {
            logger.error("Empty device name")
            return nil
        }

        self.deviceName = deviceName
        self.peripheral = peripheral
        hasAcsSupport = ScanResult.hasAcsSupport(advertismentData: advertismentData)
    }

    private static func hasAcsSupport(advertismentData: [String: Any]) -> Bool {
        guard let manufacturerData = advertismentData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return false
        }

        return manufacturerData[2] >= 2
    }
}
