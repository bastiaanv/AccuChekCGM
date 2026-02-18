import CoreBluetooth
import HealthKit
import LoopKit

protocol StateObserver: AnyObject {
    func stateDidUpdate(_ state: AccuChekState)
}

public class AccuChekCgmManager: CGMManager {
    public static var pluginIdentifier: String = "AccuChek"
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

    public required init?(rawState: RawStateValue) {
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

    public func fetchNewDataIfNeeded(_ completion: @escaping (LoopKit.CGMReadingResult) -> Void) {
        completion(.noData)
    }

    internal func notifyNewData(measurements: [CgmMeasurement]) {
        guard !measurements.isEmpty, let startTime = state.cgmStartTime else {
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

        let packet = CalibratePacket(glucoseInMgDl: glucose, cgmStartTime: startTime)
        if !bluetooth.write(packet: packet, service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_CONTROL_POINT) {
            logger.error("Failed to write calibration to sensor...")
            return false
        }

        Thread.sleep(forTimeInterval: .seconds(2))

        guard let cgmStatus = bluetooth.read(service: CBUUID.CGM_SERVICE, characteristic: CBUUID.CGM_STATUS) else {
            logger.error("Failed to read sensor status")
            return false
        }

        let response = SensorStatus(data: cgmStatus)
        notifyNewStatus(response)

        return true
    }

    internal func notifyNewStatus(_ status: SensorStatus) {
        state.cgmStatus = status.status
        state.cgmStatusTimestamp = Date.now
        notifyStateDidChange()

        if status.status.contains(where: { $0 == .timeSynchronizationRequired }) {}

        let notifications = status.status.compactMap(\.notification)
        if !notifications.isEmpty {
            NotificationHelper.sendCgmAlert(alerts: notifications)
        }
    }

    internal func cleanup() {
        state.previousDeviceName = state.deviceName
        state.deviceName = nil
        notifyStateDidChange()

        bluetooth.stopScan()
        bluetooth.disconnect()
    }

    public func delete(completion: @escaping () -> Void) {
        logger.info("Delete action triggered")
        cleanup()

        notifyDelegateOfDeletion(completion: completion)
    }
}

extension AccuChekCgmManager {
    func addStateObserver(state: StateObserver, queue: DispatchQueue) {
        stateObservers.insert(state, queue: queue)
    }

    func removeStateObserver(state: StateObserver) {
        stateObservers.removeElement(state)
    }

    func notifyStateDidChange() {
        stateObservers.forEach { observer in
            observer.stateDidUpdate(self.state)
        }

        delegate.notify { cgmManagerDelegate in
            guard let cgmManagerDelegate = cgmManagerDelegate else {
                self.logger.warning("Skip notifying delegate as no delegate set...")
                return
            }

            cgmManagerDelegate.cgmManagerDidUpdateState(self)
        }
    }
}

public extension AccuChekCgmManager {
    func acknowledgeAlert(alertIdentifier _: LoopKit.Alert.AlertIdentifier, completion: @escaping ((any Error)?) -> Void) {
        completion(nil)
    }

    func getSoundBaseURL() -> URL? {
        nil
    }

    func getSounds() -> [LoopKit.Alert.Sound] {
        []
    }
}
