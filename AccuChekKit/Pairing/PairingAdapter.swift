import CoreBluetooth

protocol PairingAdapter {
    var logger: AccuChekLogger { get }
    var peripheralManager: AccuChekPeripheralManager { get }
    var cgmManager: AccuChekCgmManager { get }

    func pair() -> Bool
    func initialize() -> Bool
}

extension PairingAdapter {
    func configureSensor() {
        getSensorStatus()

        let startTime = getSensorStartTime()
        guard let startTime else {
            logger.warning("Failed to fetch start time...")
            return
        }

        if let sensorInfo = getSensorInfo() {
            cgmManager.state.sensorInfo = sensorInfo
            cgmManager.notifyStateDidChange()
        }

        getLastCalibration(startTime: startTime)

        guard startTime.addingTimeInterval(.hours(1)) < Date.now else {
            logger.warning("Do not fetch glucose measurement during warmup or without start time")
            return
        }

        guard let currentReading = getCurrentMeasurement() else {
            logger.warning("Failed to read CGM measurements")
            return
        }

        if !currentReading.isEmpty {
            cgmManager.notifyNewData(measurements: currentReading)
        }
    }

    private func getSensorStartTime() -> Date? {
        guard let data = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_SESSION_START)
        else {
            logger.error("Failed to read CGM start time")
            return nil
        }

        let response = CgmStartTime(data)
        logger.info(response.describe)

        cgmManager.state.cgmStartTime = response.start
        cgmManager.notifyStateDidChange()

        return response.start
    }

    internal func getSensorInfo() -> SensorInfo? {
        var manufacturer = ""
        if let manufacturerData = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_MANUFACTURER) {
            manufacturer = manufacturerData.toString()
        } else {
            logger.error("Failed to read manufacturer")
        }

        var model = ""
        if let modelData = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_MODEL) {
            model = modelData.toString()
        } else {
            logger.error("Failed to read model")
        }

        var serialNumber = ""
        if let serialNumberData = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_SERIAL_NUMBER) {
            serialNumber = serialNumberData.toString()
        } else {
            logger.error("Failed to read serialNumber")
        }

        var firmware = ""
        if let firmwareData = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_FIRMWARE_REVISION) {
            firmware = firmwareData.toString()
        } else {
            logger.error("Failed to read firmware")
        }

        var hardware = ""
        if let hardwareData = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_HARDWARE_REVISION) {
            hardware = hardwareData.toString()
        } else {
            logger.error("Failed to read hardware")
        }

        var software = ""
        if let softwareData = peripheralManager.read(service: CBUUID.DIS_SERVICE, characteristic: CBUUID.DIS_SOFTWARE_REVISION) {
            software = softwareData.toString()
        } else {
            logger.error("Failed to read software")
        }

        let sensorInfo = SensorInfo(
            manufacturer: manufacturer,
            model: model,
            serialNumber: serialNumber,
            firmwareRevision: firmware,
            hardwareRevision: hardware,
            softwareRevision: software
        )

        logger.info(sensorInfo.describe)
        return sensorInfo
    }

    private func getLastCalibration(startTime: Date) {
        let lastCalibration = GetCalibrationPacket(recordIndex: 0xFFFF)
        guard peripheralManager.write(
            packet: lastCalibration,
            service: CBUUID.CGM_SERVICE,
            characteristic: CBUUID.CGM_CONTROL_POINT
        )
        else {
            logger.error("Failed to read last calibration")
            return
        }

        if lastCalibration.nextCalibrationOffset == 0xFFFF {
            cgmManager.state.nextCalibrationAt = nil
            cgmManager.state.calibrationPhase = .done
        } else {
            let offset = TimeInterval(minutes: Double(lastCalibration.nextCalibrationOffset))
            cgmManager.state.nextCalibrationAt = startTime.addingTimeInterval(offset)

            let warmupCalibration = GetCalibrationPacket(recordIndex: 0)
            guard peripheralManager.write(
                packet: warmupCalibration,
                service: CBUUID.CGM_SERVICE,
                characteristic: CBUUID.CGM_CONTROL_POINT
            )
            else {
                logger.error("Failed to read warmup calibration")
                return
            }

            if warmupCalibration.recordNumber == lastCalibration.recordNumber {
                cgmManager.state.calibrationPhase = .warmingup
            } else {
                cgmManager.state.calibrationPhase = .calibratedOnce
            }
        }

        cgmManager.notifyStateDidChange()
    }

    private func getCurrentMeasurement() -> [CgmMeasurement]? {
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

    private func getSensorStatus() {
        guard let statusData = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS)
        else {
            logger.error("Failed to read sensorStatus")
            return
        }

        var response = SensorStatus(data: statusData)
        if response.status.contains(where: { $0 == .timeSynchronizationRequired }) {
            setStartTime()

            guard let statusData = peripheralManager.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS)
            else {
                logger.error("Failed to read sensorStatus")
                return
            }
            response = SensorStatus(data: statusData)
        }

        cgmManager.notifyNewStatus(response)
        logger.info(response.describe)
    }

    private func setStartTime() {
        let startTime = Date.now
        cgmManager.state.cgmStartTime = startTime
        cgmManager.notifyStateDidChange()

        let packet = SetStartTimePacket(date: startTime)
        guard peripheralManager.write(packet: packet, service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_SESSION_START)
        else {
            logger.error("Failed to write session start")
            return
        }
    }
}
