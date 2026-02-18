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
        logger.info("\(peripheral), adver: \(advertismentData)")
        guard let manufacturerData = advertismentData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            logger.warning("Empty manufacterer data")
            return nil
        }
        
        guard let deviceName = peripheral.name else {
            logger.warning("Empty device name")
            return nil
        }

        self.deviceName = deviceName
        self.peripheral = peripheral
        self.hasAcsSupport = manufacturerData[2] >= 2
    }
}
