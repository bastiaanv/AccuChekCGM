import CoreBluetooth

class AcsAdapter: PairingAdapter {
    internal let logger = AccuChekLogger(category: "AcsAdapter")
    internal let cgmManager: AccuChekCgmManager
    internal let peripheralManager: AccuChekPeripheralManager

    internal var sensorRevisionInfo: SensorInfo?
    internal let descriptorPacket = GetAllActiveDescriptorsPacket()

    init(cgmManager: AccuChekCgmManager, peripheralManager: AccuChekPeripheralManager) {
        self.cgmManager = cgmManager
        self.peripheralManager = peripheralManager
    }

    func pair() {
        guard peripheralManager.read(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_STATUS) != nil else {
            logger.error("Failed to read ACS status")
            return
        }

        peripheralManager.startNotify(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_DATA_OUT_NOTIFY)
        peripheralManager.startNotify(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_DATA_OUT_INDICATE)

        sensorRevisionInfo = getSensorInfo()
    }

    func initialize() -> Bool {
        if cgmManager.state.aesKey != nil {
            logger.info("Used auth bypass")
            return true
        }

        peripheralManager.startNotify(service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT)

        let mtuPacket = GetAttMtuPacket()
        if !peripheralManager.write(packet: mtuPacket, service: CBUUID.ACS_SERVICE, characteristic: CBUUID.ACS_CONTROL_POINT) {
            logger.error("Failed to write to GetAttMtu")
            return false
        }

        cgmManager.state.mtu = mtuPacket.mtu

        if !peripheralManager.write(
            packet: descriptorPacket,
            service: CBUUID.ACS_SERVICE,
            characteristic: CBUUID.ACS_CONTROL_POINT
        ) {
            logger.error("Failed to write to GetAllActiveDescriptors")
            return false
        }

        // TODO: GetResourceHandleToUuidMap

        return doKeyExchange()
    }

    func getSensorInfo() -> SensorInfo? {
        guard let manufacturer = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_MANUFACTURER)
        else {
            logger.error("Failed to read manufacturer")
            return nil
        }

        guard let model = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_MODEL)
        else {
            logger.error("Failed to read model")
            return nil
        }

        guard let serialNumber = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_SERIAL_NUMBER)
        else {
            logger.error("Failed to read firmware revision")
            return nil
        }

        var firmware: String = ""
        var hardware: String = ""
        var software: String = ""
        if self as? AcsAdapter != nil {
            guard let firmwareData = peripheralManager.read(
                service: CBUUID.DIS_SERVICE,
                characteristic: CBUUID.DIS_FIRMWARE_REVISION
            )
            else {
                logger.error("Failed to read firmware revision")
                return nil
            }
            firmware = firmwareData.toString()

            guard let hardwareData = peripheralManager.read(
                service: CBUUID.DIS_SERVICE,
                characteristic: CBUUID.DIS_HARDWARE_REVISION
            )
            else {
                logger.error("Failed to read firmware revision")
                return nil
            }
            hardware = hardwareData.toString()

            guard let softwareData = peripheralManager.read(
                service: CBUUID.DIS_SERVICE,
                characteristic: CBUUID.DIS_SOFTWARE_REVISION
            )
            else {
                logger.error("Failed to read firmware revision")
                return nil
            }

            software = softwareData.toString()
        }

        let sensorInfo = SensorInfo(
            manufacturer: manufacturer.toString(),
            model: model.toString(),
            serialNumber: serialNumber.toString(),
            firmwareRevision: firmware,
            hardwareRevision: hardware,
            softwareRevision: software
        )

        logger.info(sensorInfo.describe)
        return sensorInfo
    }
}
