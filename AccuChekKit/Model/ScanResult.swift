import CoreBluetooth

class ScanResult {
    private let logger = AccuChekLogger(category: "ScanResult")

    public let deviceName: String
    public let hasAcsSupport: Bool
    public let peripheral: CBPeripheral

    init?(peripheral: CBPeripheral, advertismentData: [String: Any]) {
        guard let deviceName = peripheral.name else {
            logger.error("Empty device name")
            return nil
        }
        guard let manufacturerData = advertismentData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            logger.error("No manufacturer data")
            return nil
        }

        let id = manufacturerData.getUInt16(offset: 0)
        guard id == 0x0170 else {
            logger.error("Invalid manufacturer data: \(id)")
            return nil
        }

        self.deviceName = deviceName
        hasAcsSupport = manufacturerData[2] >= 2
        self.peripheral = peripheral
    }
}
