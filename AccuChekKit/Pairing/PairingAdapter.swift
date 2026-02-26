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

    private func getLastCalibration(startTime: Date) {
        let getCalibration = GetCalibrationPacket(recordIndex: 0xFFFF)
        guard peripheralManager.write(
            packet: getCalibration,
            service: CBUUID.CGM_SERVICE,
            characteristic: CBUUID.CGM_CONTROL_POINT
        )
        else {
            logger.error("Failed to read last calibration")
            return
        }

        if getCalibration.nextCalibrationOffset == 0xFFFF {
            cgmManager.state.nextCalibrationAt = nil
        } else {
            let offset = TimeInterval(minutes: Double(getCalibration.nextCalibrationOffset))
            cgmManager.state.nextCalibrationAt = startTime.addingTimeInterval(offset)
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
        let packet = SetStartTimePacket(date: Date.now)
        guard peripheralManager.write(packet: packet, service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_SESSION_START)
        else {
            logger.error("Failed to write session start")
            return
        }
    }
}
