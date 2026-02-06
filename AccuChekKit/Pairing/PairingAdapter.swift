import CoreBluetooth

protocol PairingAdapter {
    var logger: AccuChekLogger { get }
    var peripheralManager: AccuChekPeripheralManager { get }
    var cgmManager: AccuChekCgmManager { get }

    func pair()
    func initialize() -> Bool
}

extension PairingAdapter {
    func parseCgmMeasurement(data _: Data) {}

    func configureSensor() {
        guard let sensorInfo = getSensorInfo() else {
            logger.error("Failed to read Sensor info...")
            return
        }

        logger.info(sensorInfo.describe)

        guard let status = getSensorStatus() else {
            logger.error("Failed to read Sensor status...")
            return
        }

        logger.info(status.describe)
    }

    func getSensorStatus() -> SensorStatus? {
        guard let statusData = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS)
        else {
            logger.error("Failed to read sensorStatus")
            return nil
        }

        return SensorStatus(data: statusData)
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

        return SensorInfo(
            manufacturer: manufacturer.toString(),
            model: model.toString(),
            serialNumber: serialNumber.toString(),
            firmwareRevision: firmware,
            hardwareRevision: hardware,
            softwareRevision: software
        )
    }
}
