import CoreBluetooth

protocol PairingAdapter {
    var logger: AccuChekLogger { get }
    var peripheralManager: AccuChekPeripheralManager { get }
    var cgmManager: AccuChekCgmManager { get }

    func pair()
    func initialize() -> Bool
}

extension PairingAdapter {
    func configureSensor() {
        _ = getSensorInfo()
        getSensorStatus()
        getSensorStartTime()

        guard let currentReading = getCurrentMeasurement() else {
            logger.error("Failed to read CGM start time")
            return
        }

        if !currentReading.isEmpty {
            cgmManager.notifyNewData(measurements: currentReading)
        }
    }

    func getSensorStartTime() {
        guard let data = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_SESSION_START)
        else {
            logger.error("Failed to read CGM start time")
            return
        }

        let response = CgmStartTime(data)
        logger.info(response.describe)

        cgmManager.state.cgmStartTime = response.start
        cgmManager.notifyStateDidChange()
    }

    func getCurrentMeasurement() -> [CgmMeasurement]? {
        guard let startOffset = cgmManager.state.lastGlucoseOffset else {
            logger.warning("No offser avaiable...")
            return []
        }

        let lastMeasurement = GetLastCgmMeasurementPacket(startOffset: UInt16(startOffset.minutes))
        guard peripheralManager.write(packet: lastMeasurement, service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_RACP)
        else {
            logger.error("Failed to read current measurement")
            return nil
        }

        logger.info(lastMeasurement.describe)
        return lastMeasurement.measurements
    }

    func getSensorStatus() {
        guard let statusData = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS)
        else {
            logger.error("Failed to read sensorStatus")
            return
        }

        let response = SensorStatus(data: statusData)
        logger.info(response.describe)
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
