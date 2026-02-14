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
        getSensorStartTime()

        guard let currentReading = getCurrentMeasurement() else {
            logger.error("Failed to read CGM start time")
            return
        }

        if !currentReading.isEmpty {
            cgmManager.notifyNewData(measurements: currentReading)
        }
    }

    private func getSensorStartTime() {
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
