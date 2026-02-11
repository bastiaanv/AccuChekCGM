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
        cgmManager.notifyNewStatus(response)

        logger.info(response.describe)
    }
}
