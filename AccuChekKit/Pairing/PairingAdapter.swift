import CoreBluetooth

protocol PairingAdapter {
    var logger: AccuChekLogger { get }
    var peripheralManager: AccuChekPeripheralManager { get }
    var cgmManager: AccuChekCgmManager { get }

    func pair()
    func initialize() -> Bool
    func configureSensor()
}

extension PairingAdapter {
    func getSensorRevisionInfo() -> SensorRevisionInfo? {
        guard let serialNumber = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_SERIAL_NUMBER)
        else {
            logger.error("Failed to read firmware revision")
            return nil
        }

        guard let firmware = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_FIRMWARE_REVISION)
        else {
            logger.error("Failed to read firmware revision")
            return nil
        }

        guard let hardware = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_HARDWARE_REVISION)
        else {
            logger.error("Failed to read firmware revision")
            return nil
        }

        guard let software = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_SOFTWARE_REVISION)
        else {
            logger.error("Failed to read firmware revision")
            return nil
        }

        return SensorRevisionInfo(
            serialNumber: serialNumber.toString(),
            firmwareRevision: firmware.toString(),
            hardwareRevision: hardware.toString(),
            softwareRevision: software.toString()
        )
    }
}
