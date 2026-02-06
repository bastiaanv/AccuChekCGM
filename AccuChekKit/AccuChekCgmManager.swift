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
        nil
    }

    public var cgmManagerStatus: LoopKit.CGMManagerStatus {
        LoopKit.CGMManagerStatus(
            hasValidSensorSession: state.onboarded,
            lastCommunicationDate: state.lastGlucoseTimestamp,
            device: device
        )
    }

    internal var device: HKDevice {
        HKDevice(
            name: "AC-RANDOM",
            manufacturer: "Roche",
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

    internal func notifyNewData(measurement: CgmMeasurement) {
        delegate.notify { cgmDelegate in
            cgmDelegate?.cgmManager(self, hasNew: .newData([
                NewGlucoseSample(
                    cgmManager: self,
                    value: measurement.glucoseInMgDl,
                    trend: measurement.getTrend(),
                    dateTime: Date.now // TODO: Fixme
                )
            ]))
        }
    }

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
