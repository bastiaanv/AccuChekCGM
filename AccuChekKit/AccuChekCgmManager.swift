import CoreBluetooth
import HealthKit
import LoopKit

protocol StateObserver: AnyObject {
    func stateDidUpdate(_ state: AccuChekState)
}

public class AccuChekCgmManager: CGMManager {
    public let pluginIdentifier: String = "AccuChek"
    public var localizedTitle: String = "Accu-Chek SmartGuide CGM"

    public let providesBLEHeartbeat: Bool = true
    public let shouldSyncToRemoteService: Bool = true
    public let managedDataInterval: TimeInterval? = .hours(3)

    private let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()
    private let stateObservers = WeakSynchronizedSet<StateObserver>()

    private let logger = AccuChekLogger(category: "CgmManager")
    let bluetooth: AccuChekBluetoothManager
    var state: AccuChekState
    public var rawState: RawStateValue {
        state.rawValue
    }

    public var isOnboarded: Bool {
        state.onboarded
    }

    public var debugDescription: String {
        state.debugDescription
    }
    
    public var inSignalLoss: Bool {
        guard let lastGlucoseDate = state.lastGlucoseDate else {
            return false
        }
        
        return Date.now.timeIntervalSince(lastGlucoseDate) > .minutes(15)
    }
    
    public var isInoperable: Bool {
        // EversenseKit reports connection/sensor state via state.connectionStatus;
        // we treat anything other than .connected as not-inoperable but stale.
        false
    }

    public required init(rawState: RawStateValue) {
        state = AccuChekState(rawValue: rawState)
        bluetooth = AccuChekBluetoothManager()

        bluetooth.cgmManager = self
    }

    public weak var cgmManagerDelegate: CGMManagerDelegate? {
        get { delegate.delegate }
        set { delegate.delegate = newValue }
    }

    public var delegateQueue: DispatchQueue! {
        get { delegate.queue }
        set { delegate.queue = newValue }
    }

    public var glucoseDisplay: (any LoopKit.GlucoseDisplayable)? {
        GlucoseDisplay(state: state)
    }

    public var cgmManagerStatus: LoopKit.CGMManagerStatus {
        var lastComm: Date?
        if let cgmStartTime = state.cgmStartTime, let lastGlucoseOffset = state.lastGlucoseOffset {
            lastComm = cgmStartTime.addingTimeInterval(lastGlucoseOffset)
        }

        return LoopKit.CGMManagerStatus(
            hasValidSensorSession: state.onboarded,
            lastCommunicationDate: lastComm,
            device: device
        )
    }

    internal var device: HKDevice {
        HKDevice(
            name: state.deviceName,
            manufacturer: "Roche Diabetes Care GmbH",
            model: nil,
            hardwareVersion: nil,
            firmwareVersion: nil,
            softwareVersion: nil,
            localIdentifier: nil,
            udiDeviceIdentifier: nil
        )
    }

    public var sensorName: String? {
        guard let deviceName = state.deviceName else {
            return nil
        }

        return String(deviceName.dropFirst(3))
    }

    public var sensorActivatedAt: Date? {
        state.cgmStartTime
    }

    public func fetchNewDataIfNeeded(_ completion: @escaping (LoopKit.CGMReadingResult) -> Void) {
        completion(.noData)
    }

    internal func notifyNewData(measurements: [CgmMeasurement]) {
        guard let lastMeasurement = state.lastGlucoseDate, let startTime = state.cgmStartTime else {
            return
        }

        // Prevent duplicated measurements
        let measurements = measurements.filter { startTime.addingTimeInterval($0.timeOffset) > lastMeasurement }
        guard !measurements.isEmpty else {
            return
        }

        // If the sensor has not been calibrated twice
        // we fetch the latest sensor status in order
        // to ensure that calibration is truly available.
        // (sensor is source of truth)
        if state.calibrationPhase != .done {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self, let status = readSensorStatus() else { return }

                logger.info(status.describe)
                DispatchQueue.main.async {
                    self.notifyNewStatus(status)
                }
            }
        }

        if startTime.addingTimeInterval(.hours(1)) >= Date.now {
            logger.info("Ignoring cgm data during warming up")
            return
        }

        if let lastMeasurement = measurements.last {
            state.lastGlucoseValue = lastMeasurement.glucoseInMgDl
            state.lastGlucoseDate = startTime.addingTimeInterval(lastMeasurement.timeOffset)
            state.lastGlucoseOffset = lastMeasurement.timeOffset
            notifyStateDidChange()
        }

        delegate.notify { cgmDelegate in
            guard let cgmDelegate else { return }

            cgmDelegate.cgmManager(self, hasNew: .newData(
                measurements.map {
                    NewGlucoseSample(
                        cgmManager: self,
                        value: $0.glucoseInMgDl,
                        condition: $0.condition,
                        trend: $0.getTrend(),
                        dateTime: startTime.addingTimeInterval($0.timeOffset)
                    )
                }
            ))
        }
    }

    internal func calibrateSensor(glucose: UInt16) -> Bool {
        guard let startTime = state.cgmStartTime else {
            logger.error("No start time...")
            return false
        }

        let calibratePacket = CalibratePacket(glucoseInMgDl: glucose, cgmStartTime: startTime)

        // Ignore response, since no response will be given by CGM
        _ = bluetooth.write(packet: calibratePacket, service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_CONTROL_POINT)

        let getCalibrationPacket = GetCalibrationPacket(recordIndex: 0xFFFF)
        guard bluetooth
            .write(packet: getCalibrationPacket, service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_CONTROL_POINT)
        else {
            logger.error("Failed to read last calibration")
            return false
        }

        logger.info(getCalibrationPacket.describe)

        if getCalibrationPacket.calibrationStatus == .ok {
            if getCalibrationPacket.nextCalibrationOffset == 0xFFFF {
                state.nextCalibrationAt = nil
                state.calibrationPhase = .done
            } else {
                let offset = TimeInterval(minutes: Double(getCalibrationPacket.nextCalibrationOffset))
                state.nextCalibrationAt = startTime.addingTimeInterval(offset)
                state.calibrationPhase = .calibratedOnce
            }

            guard let cgmStatus = bluetooth.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS) else {
                logger.error("Failed to read sensor status")
                return false
            }

            let response = SensorStatus(data: cgmStatus)
            logger.info(response.describe)
            notifyNewStatus(response)
        }

        return true
    }

    internal var readingsUnavailable: Bool {
        get { state.readingsUnavailable }
        set {
            // Check if the value has actually changed to avoid unnecessary state changes
            guard state.readingsUnavailable != newValue else { return }
            state.readingsUnavailable = newValue
            notifyStateDidChange()
        }
    }

    internal func notifyNewStatus(_ status: SensorStatus) {
        state.cgmStatus = status.status
        state.cgmStatusTimestamp = Date.now
        notifyStateDidChange()

        var statusList = status.status
        if statusList.contains(.calibrationNotAllowed) {
            statusList = statusList.filter { $0 != .calibrationRecommended && $0 != .calibrationRequired }
        }

        sendAlert(alerts: statusList)
    }

    internal func readSensorStatus() -> SensorStatus? {
        guard let cgmStatus = bluetooth.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS) else {
            logger.error("Failed to read sensor status for calibration gate")
            return nil
        }

        return SensorStatus(data: cgmStatus)
    }

    internal func cleanup() {
        state.previousDeviceName = state.deviceName
        state.deviceName = nil
        state.sensorInfo = nil
        notifyStateDidChange()

        bluetooth.stopScan()
        bluetooth.disconnect()
    }

    public func delete(completion: @escaping () -> Void) {
        logger.info("Delete action triggered")
        cleanup()

        notifyDelegateOfDeletion(completion: completion)
    }

    private func sendAlert(alerts: [SensorStatusEnum]) {
        guard let delegate = delegate.delegate else {
            return
        }

        Task {
            for alert in alerts.compactMap(\.notification) {
                await delegate.issueAlert(alert)
            }
        }
    }
}

extension AccuChekCgmManager {
    func addStateObserver(state: StateObserver, queue: DispatchQueue) {
        stateObservers.insert(state, queue: queue)
    }

    func removeStateObserver(state: StateObserver) {
        stateObservers.removeElement(state)
    }

    func notifyUpdatedCgm(type: CgmEventType) {
        delegate.notify {
            guard let cgmManagerDelegate = $0 else {
                self.logger.warning("Skip notifying delegate as no delegate set...")
                return
            }

            let event = PersistedCgmEvent(
                date: self.state.cgmStartTime ?? Date.now,
                type: type,
                deviceIdentifier: self.state.deviceName ?? "",
                expectedLifetime: type == .sensorStart ? .days(14) : nil,
                warmupPeriod: type == .sensorStart ? .hours(1) : nil
            )
            cgmManagerDelegate.cgmManager(self, hasNew: [event])
        }
    }

    func notifyStateDidChange() {
        stateObservers.forEach { observer in
            observer.stateDidUpdate(self.state)
        }

        delegate.notify {
            guard let cgmManagerDelegate = $0 else {
                self.logger.warning("Skip notifying delegate as no delegate set...")
                return
            }

            cgmManagerDelegate.cgmManagerDidUpdateState(self)
        }
    }
}

public extension AccuChekCgmManager {
    func acknowledgeAlert(alertIdentifier _: LoopKit.Alert.AlertIdentifier) async throws {}

    func getSoundBaseURL() -> URL? {
        nil
    }

    func getSounds() -> [LoopKit.Alert.Sound] {
        []
    }
}
