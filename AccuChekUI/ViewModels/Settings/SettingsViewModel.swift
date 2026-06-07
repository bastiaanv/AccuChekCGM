import Combine
import HealthKit
import LoopKit
import SwiftUI

enum CGMState {
    case warmingup
    case active
    case expired
}

enum SensorStatusSeverity {
    case neutral
    case good
    case warning
    case critical
}

// A single, ordered view of sensor status. Evaluated by precedence (faults
// override lifecycle); the first matching case wins. Calibration availability is
// driven by the sensor-reported nextCalibrationAt, not the inferred phase.
enum SensorStatusDisplay: CaseIterable, Hashable {
    case connecting
    case expired
    case malfunction
    case readingsUnavailable
    case batteryLow
    case temperature
    // Trend mode (pre-first-calibration). When calibration is due, the row gains a
    // Start button, "calibrate now" copy, and escalates to warning.
    case trendMode(calibrationDue: Bool)
    // Therapy mode (after first calibration). When the second calibration is due,
    // the row escalates from warning to critical and gains a Start button.
    case therapyMode(calibrationDue: Bool)
    case ok

    static var allCases: [SensorStatusDisplay] {
        [
            .connecting, .expired, .malfunction, .readingsUnavailable, .batteryLow, .temperature,
            .trendMode(calibrationDue: false), .trendMode(calibrationDue: true),
            .therapyMode(calibrationDue: false), .therapyMode(calibrationDue: true),
            .ok
        ]
    }

    var severity: SensorStatusSeverity {
        switch self {
        case .connecting,
             .trendMode(calibrationDue: false): return .neutral
        case .ok: return .good
        case .temperature,
             .therapyMode(calibrationDue: false),
             .trendMode(calibrationDue: true): return .warning
        case .batteryLow,
             .expired,
             .malfunction,
             .readingsUnavailable,
             .therapyMode(calibrationDue: true): return .critical
        }
    }

    var showsCalibrationButton: Bool {
        switch self {
        case .therapyMode(calibrationDue: true),
             .trendMode(calibrationDue: true): return true
        default: return false
        }
    }
}

class SettingsViewModel: ObservableObject {
    @Published var cgmState = CGMState.warmingup
    @Published var connected: Bool = false
    @Published var deviceName: String = ""
    @Published var lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: 0)
    @Published var lastMeasurementDatetime: String = ""
    @Published var nextCalibrationDate: String? = nil
    @Published var sensorStartedAt: String = ""
    @Published var sensorEndsAt: String = ""
    @Published var sensorAgeProcess: Double = 0
    @Published var sensorAgeDays: Double = 0
    @Published var sensorAgeHours: Double = 0
    @Published var sensorAgeMinutes: Double = 0
    @Published var sensorWarmupProgress: Double = 0
    @Published var sensorWarmupMinutes: Double = 0
    @Published var notifications: [NotificationContent] = []
    @Published var readingsUnavailable: Bool = false

    // Demo only (simulator): when set, the status row renders this overridden
    // value so each variant can be previewed without a device.
    @Published var demoStatus: SensorStatusDisplay? = nil

    @Published var calibrationAvailable: Bool = false
    @Published var calibrationPhase: CalibrationPhase = .done
    // Set by a live CGM_STATUS read on settings open; gates the calibration prompt
    // so we only offer Start when the sensor actually signals calibration is
    // allowed, not on the time estimate alone.
    @Published var calibrationConfirmed: Bool = false

    @Published var isSharePresented = false
    @Published var showingDeleteConfirmation = false
    @Published var showingRepairConfirmation = false

    private let timeFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private let dateTimeFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let logger = AccuChekLogger(category: "SettingsViewModel")
    private let cgmManager: AccuChekCgmManager
    let doCalibration: () -> Void
    private let doPairing: () -> Void
    let deleteCGM: () -> Void
    init(
        _ cgmManager: AccuChekCgmManager,
        doCalibration: @escaping () -> Void,
        doPairing: @escaping () -> Void,
        deleteCGM: @escaping () -> Void
    ) {
        self.cgmManager = cgmManager
        self.doCalibration = doCalibration
        self.doPairing = doPairing
        self.deleteCGM = deleteCGM

        stateDidUpdate(cgmManager.state)
        cgmManager.addStateObserver(state: self, queue: DispatchQueue.main)
    }

    deinit {
        cgmManager.removeStateObserver(state: self)
    }

    // The BLE name (e.g. "AC-1R...") doubles as the reconnection key, so it's kept
    // verbatim in state. The serial printed on the packaging is the part after the
    // "AC-" prefix, shown with GS1 application identifier (21).
    var serialNumberDisplay: String {
        guard deviceName.hasPrefix("AC-") else {
            return deviceName
        }
        return "(21) " + deviceName.dropFirst(3)
    }

    var sensorStatus: SensorStatusDisplay {
        if let demoStatus {
            return demoStatus
        }

        func hasNotification(_ type: SensorStatusEnum) -> Bool {
            notifications.contains { $0.type == type }
        }

        if !connected {
            return .connecting
        }
        if cgmState == .expired || hasNotification(.sessionStopped) {
            return .expired
        }
        if hasNotification(.generalDeviceFaultOccuredInSensor) {
            return .malfunction
        }
        if readingsUnavailable {
            return .readingsUnavailable
        }
        if hasNotification(.deviceBatteryLow) {
            return .batteryLow
        }
        if hasNotification(.sensorTemperatureTooHigh) || hasNotification(.sensorTemperatureTooLow) {
            return .temperature
        }

        // Calibration progression. The sensor starts in trend mode (.warmingup);
        // the first calibration moves it to therapy mode (.calibratedOnce). A second
        // calibration within its window keeps it in therapy mode (.done); miss it and
        // the sensor falls back to trend mode. Availability (now >= the sensor-
        // reported time) gates whether we prompt to calibrate vs. announce the time.
        // Only prompt to calibrate when the time has passed AND a live status read
        // confirmed the sensor is actually signalling calibration is allowed.
        let calibrationDue = calibrationAvailable && calibrationConfirmed

        switch calibrationPhase {
        case .warmingup:
            return .trendMode(calibrationDue: calibrationDue)
        case .calibratedOnce:
            return .therapyMode(calibrationDue: calibrationDue)
        case .done:
            return cgmState == .warmingup ? .trendMode(calibrationDue: false) : .ok
        }
    }

    // Called when the settings screen appears. If the calibration time has passed,
    // do one live CGM_STATUS read to confirm the sensor actually allows calibration
    // before we offer the Start button. Kept to settings-open (not every state
    // tick) to avoid spamming BLE reads.
    func refreshCalibrationConfirmation() {
        guard calibrationAvailable, connected else {
            calibrationConfirmed = false
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let status = cgmManager.readSensorStatus()
            DispatchQueue.main.async {
                guard let status else {
                    self.calibrationConfirmed = false
                    return
                }
                self.cgmManager.notifyNewStatus(status)
                self.calibrationConfirmed = status.status.contains(.calibrationRecommended)
                    || status.status.contains(.calibrationRequired)
            }
        }
    }

    func getLogs() -> [URL] {
        logger.info(cgmManager.state.debugDescription)
        return logger.getDebugLogs()
    }

    func pairNewCGM() {
        cgmManager.cleanup()
        doPairing()
    }
}

extension SettingsViewModel: StateObserver {
    func stateDidUpdate(_ state: AccuChekState) {
        connected = state.isConnected
        readingsUnavailable = state.readingsUnavailable
        deviceName = state.deviceName ?? ""
        notifications = state.cgmStatus.compactMap(\.notification)
        calibrationPhase = state.calibrationPhase

        if let glucose = state.lastGlucoseValue {
            lastMeasurement = HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(glucose))
        }

        if let date = state.lastGlucoseDate {
            lastMeasurementDatetime = timeFormatter.string(from: date)
        }

        if let nextCalibrationAt = state.nextCalibrationAt {
            nextCalibrationDate = dateTimeFormatter.string(from: nextCalibrationAt)
            calibrationAvailable = Date.now >= nextCalibrationAt
        } else {
            nextCalibrationDate = nil
            calibrationAvailable = false
        }

        guard let cgmStartTime = state.cgmStartTime, let cgmEndTime = state.cgmEndTime else {
            return
        }

        let warmupEnd = cgmStartTime.addingTimeInterval(.hours(1))
        sensorStartedAt = dateTimeFormatter.string(from: cgmStartTime)
        sensorEndsAt = dateTimeFormatter.string(from: cgmEndTime)

        if cgmEndTime < Date.now {
            cgmState = .expired

        } else if warmupEnd > Date.now {
            let warmupAge = warmupEnd.timeIntervalSinceNow

            cgmState = .warmingup
            sensorWarmupProgress = min(cgmStartTime.timeIntervalSinceNow * -1 / .hours(1), 1)
            sensorWarmupMinutes = max(warmupAge / .minutes(1), 0)

        } else {
            cgmState = .active
            sensorAgeProcess = min(cgmStartTime.timeIntervalSinceNow * -1 / .days(14), 1)

            let sensorAge = cgmEndTime.timeIntervalSinceNow
            sensorAgeDays = max(floor(sensorAge / .days(1)), 0)
            sensorAgeHours = max(sensorAge.truncatingRemainder(dividingBy: .days(1)) / .hours(1), 0)
            sensorAgeMinutes = max(sensorAge.truncatingRemainder(dividingBy: .hours(1)) / .minutes(1), 0)
        }
    }
}
